CREATE TABLE `lot_transfers` (
	`id` text PRIMARY KEY NOT NULL,
	`source_id` text NOT NULL,
	`target_id` text NOT NULL,
	`quantity` integer NOT NULL,
	`reason` text NOT NULL,
	`actor` text NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`source_id`) REFERENCES `inventory_lots`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`target_id`) REFERENCES `inventory_lots`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
ALTER TABLE `orders` ADD `deleted_at` text;--> statement-breakpoint
ALTER TABLE `products` ADD `channels` text DEFAULT '["Evento","Live","Site","Consignado"]' NOT NULL;--> statement-breakpoint
ALTER TABLE `products` ADD `deleted_at` text;--> statement-breakpoint
UPDATE products SET channels=iif(published=1,'["Evento","Live","Site","Consignado"]','["Evento","Live","Consignado"]');
--> statement-breakpoint
CREATE TRIGGER lot_transfer_guard BEFORE INSERT ON lot_transfers WHEN NOT EXISTS(SELECT 1 FROM lot_transfers WHERE id=NEW.id) BEGIN
 SELECT RAISE(ABORT,'Selecione lotes diferentes e uma quantidade positiva.') WHERE NEW.source_id=NEW.target_id OR NEW.quantity<1;
 SELECT RAISE(ABORT,'Lote excluído ou inexistente.') WHERE (SELECT count(*) FROM inventory_lots l JOIN products p ON p.id=l.product_id WHERE l.id IN (NEW.source_id,NEW.target_id) AND p.deleted_at IS NULL)<>2;
 SELECT RAISE(ABORT,'Quantidade disponível insuficiente para transferir.') WHERE (SELECT count(*) FROM product_items WHERE product_id=(SELECT product_id FROM inventory_lots WHERE id=NEW.source_id) AND status='disponivel')<NEW.quantity;
END;
--> statement-breakpoint
CREATE TRIGGER lot_transfer_apply AFTER INSERT ON lot_transfers BEGIN
 UPDATE product_items SET product_id=(SELECT product_id FROM inventory_lots WHERE id=NEW.target_id),group_id=NULL,actor=NEW.actor,reason='Transferência '||NEW.id||': '||NEW.reason WHERE id IN (SELECT id FROM product_items WHERE product_id=(SELECT product_id FROM inventory_lots WHERE id=NEW.source_id) AND status='disponivel' ORDER BY seq LIMIT NEW.quantity);
END;
--> statement-breakpoint
CREATE TRIGGER lot_transfer_audit AFTER UPDATE OF product_id ON product_items WHEN OLD.product_id<>NEW.product_id BEGIN
 INSERT INTO stock_movements(item_id,type,actor,reason) VALUES(NEW.id,'transferencia',NEW.actor,NEW.reason);
END;
--> statement-breakpoint
CREATE TRIGGER product_delete_guard BEFORE UPDATE OF deleted_at ON products WHEN NEW.deleted_at IS NOT NULL BEGIN
 SELECT RAISE(ABORT,'Há unidades reservadas ou consignadas. Cancele as reservas ou acerte a consignação antes de excluir.') WHERE EXISTS(SELECT 1 FROM product_items WHERE product_id=NEW.id AND status IN ('reservado','consignado'));
END;
--> statement-breakpoint
CREATE TRIGGER order_delete_guard BEFORE UPDATE OF deleted_at ON orders WHEN NEW.deleted_at IS NOT NULL BEGIN
 SELECT RAISE(ABORT,'Cancele o pedido antes de excluir.') WHERE NEW.status IN ('novo','confirmado','preparando','draft');
END;
--> statement-breakpoint
CREATE TRIGGER order_channel_guard BEFORE INSERT ON order_items BEGIN
 SELECT RAISE(ABORT,'Produto não disponível neste canal.') WHERE NOT EXISTS(SELECT 1 FROM products p JOIN orders o ON o.id=NEW.order_id WHERE p.id=NEW.product_id AND p.deleted_at IS NULL AND EXISTS(SELECT 1 FROM json_each(p.channels) WHERE value=iif(o.origin='Live','Live','Site')));
END;
--> statement-breakpoint
CREATE TRIGGER sale_channel_guard BEFORE INSERT ON sale_lines WHEN NEW.item_id IS NOT NULL AND NEW.consignment_item_id IS NULL BEGIN
 SELECT RAISE(ABORT,'Produto não disponível neste canal.') WHERE NOT EXISTS(SELECT 1 FROM product_items i JOIN products p ON p.id=i.product_id JOIN sales s ON s.id=NEW.sale_id WHERE i.id=NEW.item_id AND p.deleted_at IS NULL AND (s.origin NOT IN ('Evento','Live') OR EXISTS(SELECT 1 FROM json_each(p.channels) WHERE value=s.origin)));
END;
--> statement-breakpoint
CREATE TRIGGER consign_channel_guard BEFORE INSERT ON consignment_items BEGIN
 SELECT RAISE(ABORT,'Produto não disponível para consignação.') WHERE NOT EXISTS(SELECT 1 FROM product_items i JOIN products p ON p.id=i.product_id WHERE i.id=NEW.item_id AND p.deleted_at IS NULL AND EXISTS(SELECT 1 FROM json_each(p.channels) WHERE value='Consignado'));
END;
