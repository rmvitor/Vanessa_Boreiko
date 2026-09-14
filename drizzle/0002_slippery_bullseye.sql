CREATE TABLE `consignment_items` (
	`id` text PRIMARY KEY NOT NULL,
	`consignment_id` text NOT NULL,
	`item_id` text NOT NULL,
	`status` text DEFAULT 'em_posse' NOT NULL,
	`price_cents` integer NOT NULL,
	`cost_cents` integer NOT NULL,
	`settled_at` text,
	FOREIGN KEY (`consignment_id`) REFERENCES `consignments`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`item_id`) REFERENCES `product_items`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `consignment_items_lot` ON `consignment_items` (`consignment_id`);--> statement-breakpoint
CREATE TABLE `consignments` (
	`id` text PRIMARY KEY NOT NULL,
	`code` text NOT NULL,
	`reseller_id` text NOT NULL,
	`commission` integer NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`actor` text NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`reseller_id`) REFERENCES `resellers`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `consignments_code_unique` ON `consignments` (`code`);--> statement-breakpoint
CREATE TABLE `customer_details` (
	`customer_id` text PRIMARY KEY NOT NULL,
	`address` text DEFAULT '' NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `expenses` (
	`id` text PRIMARY KEY NOT NULL,
	`description` text NOT NULL,
	`category` text NOT NULL,
	`amount_cents` integer NOT NULL,
	`date` text NOT NULL,
	`method` text NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`actor` text NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `order_costs` (
	`line_id` text PRIMARY KEY NOT NULL,
	`cost_cents` integer NOT NULL,
	FOREIGN KEY (`line_id`) REFERENCES `order_items`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `product_details` (
	`product_id` text PRIMARY KEY NOT NULL,
	`supplier` text DEFAULT '' NOT NULL,
	`acquired` text DEFAULT '' NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`collection` text DEFAULT '' NOT NULL,
	`featured` integer DEFAULT 0 NOT NULL,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `quick_codes` (
	`id` text PRIMARY KEY NOT NULL,
	`code` text NOT NULL,
	`name` text NOT NULL,
	`group_id` text NOT NULL,
	`category_id` text NOT NULL,
	`price_cents` integer NOT NULL,
	FOREIGN KEY (`group_id`) REFERENCES `sales_groups`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `quick_codes_code_unique` ON `quick_codes` (`code`);--> statement-breakpoint
CREATE TABLE `reseller_receipts` (
	`id` text PRIMARY KEY NOT NULL,
	`reseller_id` text NOT NULL,
	`amount_cents` integer NOT NULL,
	`date` text NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`actor` text NOT NULL,
	FOREIGN KEY (`reseller_id`) REFERENCES `resellers`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `resellers` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`phone` text NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`active` integer DEFAULT 1 NOT NULL,
	`commission` integer DEFAULT 2000 NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `sale_lines` (
	`id` text PRIMARY KEY NOT NULL,
	`sale_id` text NOT NULL,
	`item_id` text,
	`group_id` text,
	`category_id` text,
	`name` text NOT NULL,
	`price_cents` integer NOT NULL,
	`cost_cents` integer DEFAULT 0 NOT NULL,
	`commission_cents` integer DEFAULT 0 NOT NULL,
	`consignment_item_id` text,
	`quantity` integer DEFAULT 1 NOT NULL,
	FOREIGN KEY (`sale_id`) REFERENCES `sales`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`item_id`) REFERENCES `product_items`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`group_id`) REFERENCES `sales_groups`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `sale_lines_sale` ON `sale_lines` (`sale_id`);--> statement-breakpoint
CREATE TABLE `sales` (
	`id` text PRIMARY KEY NOT NULL,
	`code` text NOT NULL,
	`request_key` text NOT NULL,
	`origin` text NOT NULL,
	`customer` text DEFAULT '' NOT NULL,
	`phone` text DEFAULT '' NOT NULL,
	`method` text NOT NULL,
	`status` text DEFAULT 'draft' NOT NULL,
	`total_cents` integer NOT NULL,
	`expected` integer NOT NULL,
	`actor` text NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `sales_code_unique` ON `sales` (`code`);--> statement-breakpoint
CREATE UNIQUE INDEX `sales_request_key_unique` ON `sales` (`request_key`);--> statement-breakpoint
CREATE TRIGGER sale_line_guard BEFORE INSERT ON sale_lines BEGIN
 SELECT RAISE(ABORT,'Venda encerrada') WHERE NOT EXISTS(SELECT 1 FROM sales WHERE id=NEW.sale_id AND status='draft');
 SELECT RAISE(ABORT,'Quantidade inválida') WHERE NEW.quantity<1 OR (NEW.item_id IS NOT NULL AND NEW.quantity<>1);
 SELECT RAISE(ABORT,'Peça indisponível') WHERE NEW.item_id IS NOT NULL AND NOT EXISTS(SELECT 1 FROM product_items i JOIN products p ON p.id=i.product_id WHERE i.id=NEW.item_id AND ((NEW.consignment_item_id IS NULL AND i.status='disponivel' AND p.price_cents=NEW.price_cents AND p.cost_cents=NEW.cost_cents) OR (NEW.consignment_item_id IS NOT NULL AND i.status='consignado' AND EXISTS(SELECT 1 FROM consignment_items ci WHERE ci.id=NEW.consignment_item_id AND ci.item_id=i.id AND ci.status='em_posse'))));
END;
--> statement-breakpoint
CREATE TRIGGER sale_line_stock AFTER INSERT ON sale_lines WHEN NEW.item_id IS NOT NULL BEGIN
 UPDATE product_items SET status='vendido',actor=(SELECT actor FROM sales WHERE id=NEW.sale_id),reason='Venda '||NEW.sale_id WHERE id=NEW.item_id;
END;
--> statement-breakpoint
CREATE TRIGGER sale_validate BEFORE UPDATE OF status ON sales WHEN NEW.status='concluida' BEGIN
 SELECT RAISE(ABORT,'Venda incompleta') WHERE OLD.status<>'draft' OR NEW.expected<>(SELECT count(*) FROM sale_lines WHERE sale_id=NEW.id) OR NEW.total_cents<>(SELECT coalesce(sum(price_cents*quantity),0) FROM sale_lines WHERE sale_id=NEW.id);
END;
--> statement-breakpoint
CREATE TRIGGER sale_cancel AFTER UPDATE OF status ON sales WHEN OLD.status='concluida' AND NEW.status='cancelada' BEGIN
 UPDATE product_items SET status='disponivel',actor=NEW.actor,reason='Cancelamento da venda '||NEW.id WHERE id IN (SELECT item_id FROM sale_lines WHERE sale_id=NEW.id) AND status='vendido';
END;
--> statement-breakpoint
CREATE TRIGGER consignment_guard BEFORE INSERT ON consignment_items BEGIN
 SELECT RAISE(ABORT,'Peça indisponível para consignação') WHERE NOT EXISTS(SELECT 1 FROM product_items WHERE id=NEW.item_id AND status='disponivel');
END;
--> statement-breakpoint
CREATE TRIGGER consignment_stock AFTER INSERT ON consignment_items BEGIN
 UPDATE product_items SET status='consignado',location=(SELECT r.name FROM resellers r JOIN consignments c ON c.reseller_id=r.id WHERE c.id=NEW.consignment_id),actor=(SELECT actor FROM consignments WHERE id=NEW.consignment_id),reason='Consignação '||NEW.consignment_id WHERE id=NEW.item_id;
END;
--> statement-breakpoint
CREATE TRIGGER consignment_settle BEFORE UPDATE OF status ON consignment_items BEGIN
 SELECT RAISE(ABORT,'Acerto já realizado') WHERE OLD.status<>'em_posse' OR NEW.status NOT IN ('vendida','devolvida','perdida');
 SELECT RAISE(ABORT,'Venda não registrada') WHERE NEW.status='vendida' AND NOT EXISTS(SELECT 1 FROM sale_lines WHERE consignment_item_id=NEW.id);
END;
--> statement-breakpoint
CREATE TRIGGER consignment_return AFTER UPDATE OF status ON consignment_items WHEN NEW.status IN ('devolvida','perdida') BEGIN
 UPDATE product_items SET status=iif(NEW.status='devolvida','disponivel','inativo'),location='Loja',actor=(SELECT actor FROM consignments WHERE id=NEW.consignment_id),reason='Acerto '||NEW.status||' '||NEW.consignment_id WHERE id=NEW.item_id AND status='consignado';
END;
--> statement-breakpoint
CREATE TRIGGER piece_location_audit AFTER UPDATE OF location,group_id ON product_items WHEN (OLD.location<>NEW.location OR OLD.group_id IS NOT NEW.group_id) AND OLD.status=NEW.status BEGIN
 INSERT INTO stock_movements(item_id,type,actor,reason) VALUES(NEW.id,'localizacao',NEW.actor,NEW.reason);
END;
--> statement-breakpoint
CREATE TRIGGER snapshot_order_cost AFTER INSERT ON order_items BEGIN
 INSERT INTO order_costs(line_id,cost_cents) SELECT NEW.id,cost_cents FROM products WHERE id=NEW.product_id;
END;
--> statement-breakpoint
CREATE TRIGGER receipt_limit BEFORE INSERT ON reseller_receipts BEGIN
 SELECT RAISE(ABORT,'Valor maior que o saldo a receber') WHERE NEW.amount_cents > coalesce((SELECT sum(l.price_cents-l.commission_cents) FROM sale_lines l JOIN sales s ON s.id=l.sale_id WHERE s.origin='Revendedora' AND s.customer=NEW.reseller_id AND s.status='concluida'),0)-coalesce((SELECT sum(amount_cents) FROM reseller_receipts WHERE reseller_id=NEW.reseller_id),0);
END;
