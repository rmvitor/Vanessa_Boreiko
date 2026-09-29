CREATE TABLE `event_closures` (
	`id` text PRIMARY KEY NOT NULL,
	`session_id` text NOT NULL,
	`counts` text NOT NULL,
	`expected_cents` integer NOT NULL,
	`counted_cents` integer NOT NULL,
	`notes` text NOT NULL,
	`actor` text NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`session_id`) REFERENCES `event_sessions`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `event_closures_session_id_unique` ON `event_closures` (`session_id`);--> statement-breakpoint
CREATE TABLE `event_sessions` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`channel` text NOT NULL,
	`location` text NOT NULL,
	`status` text DEFAULT 'aberto' NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`actor` text NOT NULL,
	`closed_at` text,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `event_stock` (
	`id` text PRIMARY KEY NOT NULL,
	`session_id` text NOT NULL,
	`item_id` text NOT NULL,
	`product_id` text NOT NULL,
	`name` text NOT NULL,
	`original_location` text NOT NULL,
	`outcome` text DEFAULT 'em_local' NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`session_id`) REFERENCES `event_sessions`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`item_id`) REFERENCES `product_items`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `event_stock_unit` ON `event_stock` (`session_id`,`item_id`);--> statement-breakpoint
CREATE TABLE `routine_checks` (
	`id` text PRIMARY KEY NOT NULL,
	`period` text NOT NULL,
	`task` text NOT NULL,
	`done` integer DEFAULT 0 NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`actor` text NOT NULL,
	`updated_at` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `routine_period_task` ON `routine_checks` (`period`,`task`);--> statement-breakpoint
ALTER TABLE `orders` ADD `event_id` text;--> statement-breakpoint
ALTER TABLE `product_items` ADD `event_id` text;--> statement-breakpoint
ALTER TABLE `sales` ADD `event_id` text;--> statement-breakpoint
CREATE INDEX event_items_active ON product_items(event_id,status,product_id);
--> statement-breakpoint
CREATE TRIGGER event_dispatch_guard BEFORE INSERT ON event_stock BEGIN
 SELECT RAISE(ABORT,'Sessão encerrada ou peça indisponível para saída.') WHERE NOT EXISTS(SELECT 1 FROM product_items i JOIN products p ON p.id=i.product_id JOIN event_sessions e ON e.id=NEW.session_id WHERE i.id=NEW.item_id AND i.product_id=NEW.product_id AND i.status='disponivel' AND i.event_id IS NULL AND p.deleted_at IS NULL AND e.status='aberto' AND EXISTS(SELECT 1 FROM json_each(p.channels) WHERE value=e.channel));
END;
--> statement-breakpoint
CREATE TRIGGER event_dispatch_apply AFTER INSERT ON event_stock BEGIN
 UPDATE product_items SET event_id=NEW.session_id,location=(SELECT location FROM event_sessions WHERE id=NEW.session_id),actor=(SELECT actor FROM event_sessions WHERE id=NEW.session_id),reason='Saída para sessão '||NEW.session_id WHERE id=NEW.item_id;
END;
--> statement-breakpoint
CREATE TRIGGER event_item_lock BEFORE UPDATE ON product_items WHEN OLD.event_id IS NOT NULL AND NEW.event_id IS OLD.event_id AND (NEW.product_id<>OLD.product_id OR NEW.location<>OLD.location OR NEW.status IN ('consignado','inativo')) BEGIN
 SELECT RAISE(ABORT,'Estoque separado para live ou evento. Faça o fechamento antes de ajustar ou transferir.');
END;
--> statement-breakpoint
CREATE TRIGGER event_product_lock BEFORE UPDATE OF deleted_at ON products WHEN NEW.deleted_at IS NOT NULL BEGIN
 SELECT RAISE(ABORT,'Feche a live ou evento antes de excluir este produto.') WHERE EXISTS(SELECT 1 FROM product_items WHERE product_id=NEW.id AND event_id IS NOT NULL);
END;
--> statement-breakpoint
CREATE TRIGGER event_sale_guard BEFORE INSERT ON sale_lines WHEN NEW.item_id IS NOT NULL BEGIN
 SELECT RAISE(ABORT,'Peça fora do estoque desta sessão. Atualize o caixa.') WHERE NOT EXISTS(SELECT 1 FROM product_items i JOIN sales s ON s.id=NEW.sale_id WHERE i.id=NEW.item_id AND i.event_id IS s.event_id AND (s.event_id IS NULL OR EXISTS(SELECT 1 FROM event_sessions e WHERE e.id=s.event_id AND e.status='aberto' AND e.channel=s.origin)));
END;
--> statement-breakpoint
CREATE TRIGGER event_order_guard BEFORE INSERT ON order_items BEGIN
 SELECT RAISE(ABORT,'Peça separada para outra sessão ou indisponível no site.') WHERE NOT EXISTS(SELECT 1 FROM product_items i JOIN orders o ON o.id=NEW.order_id WHERE i.id=NEW.item_id AND i.event_id IS o.event_id AND (o.event_id IS NULL OR EXISTS(SELECT 1 FROM event_sessions e WHERE e.id=o.event_id AND e.status='aberto' AND e.channel='Live' AND o.origin='Live')));
END;
--> statement-breakpoint
CREATE TRIGGER event_consign_guard BEFORE INSERT ON consignment_items BEGIN
 SELECT RAISE(ABORT,'Peça separada para live ou evento.') WHERE EXISTS(SELECT 1 FROM product_items WHERE id=NEW.item_id AND event_id IS NOT NULL);
END;
--> statement-breakpoint
CREATE TRIGGER event_closed_sale BEFORE UPDATE OF status ON sales WHEN OLD.status<>NEW.status AND OLD.event_id IS NOT NULL BEGIN
 SELECT RAISE(ABORT,'Sessão já encerrada. O fechamento preserva as vendas conferidas.') WHERE EXISTS(SELECT 1 FROM event_sessions WHERE id=OLD.event_id AND status='fechado');
END;
--> statement-breakpoint
CREATE TRIGGER event_closed_order BEFORE UPDATE OF status,payment,total_cents ON orders WHEN OLD.event_id IS NOT NULL AND (NEW.payment<>OLD.payment OR NEW.total_cents<>OLD.total_cents OR NEW.status IN ('cancelado','expirado')) BEGIN
 SELECT RAISE(ABORT,'Sessão já encerrada. O fechamento preserva os recebimentos conferidos.') WHERE EXISTS(SELECT 1 FROM event_sessions WHERE id=OLD.event_id AND status='fechado');
END;
--> statement-breakpoint
DROP TRIGGER lot_transfer_guard;
--> statement-breakpoint
DROP TRIGGER lot_transfer_apply;
--> statement-breakpoint
CREATE TRIGGER lot_transfer_guard BEFORE INSERT ON lot_transfers WHEN NOT EXISTS(SELECT 1 FROM lot_transfers WHERE id=NEW.id) BEGIN
 SELECT RAISE(ABORT,'Selecione lotes diferentes e uma quantidade positiva.') WHERE NEW.source_id=NEW.target_id OR NEW.quantity<1;
 SELECT RAISE(ABORT,'Lote excluído ou inexistente.') WHERE (SELECT count(*) FROM inventory_lots l JOIN products p ON p.id=l.product_id WHERE l.id IN (NEW.source_id,NEW.target_id) AND p.deleted_at IS NULL)<>2;
 SELECT RAISE(ABORT,'Saldo insuficiente. Unidades separadas para sessões não podem ser transferidas.') WHERE (SELECT count(*) FROM product_items WHERE product_id=(SELECT product_id FROM inventory_lots WHERE id=NEW.source_id) AND status='disponivel' AND event_id IS NULL)<NEW.quantity;
END;
--> statement-breakpoint
CREATE TRIGGER lot_transfer_apply AFTER INSERT ON lot_transfers BEGIN
 UPDATE product_items SET product_id=(SELECT product_id FROM inventory_lots WHERE id=NEW.target_id),group_id=NULL,actor=NEW.actor,reason='Transferência '||NEW.id||': '||NEW.reason WHERE id IN (SELECT id FROM product_items WHERE product_id=(SELECT product_id FROM inventory_lots WHERE id=NEW.source_id) AND status='disponivel' AND event_id IS NULL ORDER BY seq LIMIT NEW.quantity);
END;
--> statement-breakpoint
CREATE TRIGGER event_close_guard BEFORE INSERT ON event_closures BEGIN
 SELECT RAISE(ABORT,'Sessão inexistente ou já encerrada.') WHERE NOT EXISTS(SELECT 1 FROM event_sessions WHERE id=NEW.session_id AND status='aberto');
 SELECT RAISE(ABORT,'Confirme ou cancele as reservas e confira os pagamentos antes de fechar.') WHERE EXISTS(SELECT 1 FROM product_items WHERE event_id=NEW.session_id AND status NOT IN ('disponivel','vendido')) OR EXISTS(SELECT 1 FROM orders WHERE event_id=NEW.session_id AND (status IN ('novo','draft') OR (status IN ('confirmado','preparando','enviado','entregue') AND payment<>'pago') OR (status IN ('cancelado','expirado') AND payment='pago')));
 SELECT RAISE(ABORT,'Confira todos os produtos e lotes da saída.') WHERE json_array_length(NEW.counts)<>(SELECT count(DISTINCT product_id) FROM event_stock WHERE session_id=NEW.session_id) OR json_array_length(NEW.counts)<>(SELECT count(DISTINCT json_extract(value,'$.product_id')) FROM json_each(NEW.counts));
 SELECT RAISE(ABORT,'O saldo mudou ou a contagem está inválida. Atualize antes de fechar.') WHERE EXISTS(SELECT 1 FROM json_each(NEW.counts) j WHERE NOT EXISTS(SELECT 1 FROM event_stock WHERE session_id=NEW.session_id AND product_id=json_extract(j.value,'$.product_id')) OR json_type(j.value,'$.expected') IS NOT 'integer' OR json_type(j.value,'$.returned') IS NOT 'integer' OR json_extract(j.value,'$.expected')<>(SELECT count(*) FROM product_items WHERE event_id=NEW.session_id AND product_id=json_extract(j.value,'$.product_id') AND status='disponivel') OR json_extract(j.value,'$.returned')<0 OR json_extract(j.value,'$.returned')>json_extract(j.value,'$.expected'));
 SELECT RAISE(ABORT,'Os recebimentos mudaram. Atualize a conferência.') WHERE NEW.expected_cents<>coalesce((SELECT sum(total_cents) FROM sales WHERE event_id=NEW.session_id AND status='concluida'),0)+coalesce((SELECT sum(total_cents) FROM orders WHERE event_id=NEW.session_id AND status IN ('confirmado','preparando','enviado','entregue') AND payment='pago'),0);
 SELECT RAISE(ABORT,'Informe o motivo das diferenças de estoque ou recebimento.') WHERE length(trim(NEW.notes))<3 AND (NEW.expected_cents<>NEW.counted_cents OR EXISTS(SELECT 1 FROM json_each(NEW.counts) WHERE json_extract(value,'$.returned')<>json_extract(value,'$.expected')));
END;
--> statement-breakpoint
CREATE TRIGGER event_close_apply AFTER INSERT ON event_closures BEGIN
 UPDATE event_stock SET outcome=iif(item_id IN (SELECT id FROM product_items WHERE event_id=NEW.session_id AND status='vendido'),'vendido','retornado') WHERE session_id=NEW.session_id;
 UPDATE event_stock SET outcome='divergencia' WHERE session_id=NEW.session_id AND item_id IN (SELECT ranked.id FROM (SELECT id,product_id,row_number() OVER(PARTITION BY product_id ORDER BY seq) n FROM product_items WHERE event_id=NEW.session_id AND status='disponivel') ranked JOIN json_each(NEW.counts) j ON json_extract(j.value,'$.product_id')=ranked.product_id WHERE ranked.n>json_extract(j.value,'$.returned'));
 UPDATE event_sessions SET status='fechado',closed_at=NEW.created_at WHERE id=NEW.session_id;
 UPDATE product_items SET event_id=NULL,location=(SELECT original_location FROM event_stock WHERE session_id=NEW.session_id AND item_id=product_items.id),status=iif((SELECT outcome FROM event_stock WHERE session_id=NEW.session_id AND item_id=product_items.id)='divergencia','inativo',status),actor=NEW.actor,reason='Fechamento da sessão '||NEW.session_id||': '||NEW.notes WHERE event_id=NEW.session_id;
END;
