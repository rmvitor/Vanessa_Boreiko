CREATE TABLE `inventory_lots` (
	`id` text PRIMARY KEY NOT NULL,
	`code` text NOT NULL,
	`product_id` text NOT NULL,
	`group_id` text,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`group_id`) REFERENCES `sales_groups`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `inventory_lots_code_unique` ON `inventory_lots` (`code`);--> statement-breakpoint
CREATE UNIQUE INDEX `inventory_lots_product_id_unique` ON `inventory_lots` (`product_id`);--> statement-breakpoint
CREATE TABLE `product_requests` (
	`key` text PRIMARY KEY NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL
);
--> statement-breakpoint
DROP TRIGGER order_item_available;
--> statement-breakpoint
CREATE TRIGGER order_item_available BEFORE INSERT ON order_items BEGIN
 SELECT RAISE(ABORT,'Uma peça ficou indisponível ou teve o preço alterado. Atualize o carrinho.') WHERE NOT EXISTS(SELECT 1 FROM product_items i JOIN products p ON p.id=i.product_id WHERE i.id=NEW.item_id AND i.status='disponivel' AND (p.published=1 OR EXISTS(SELECT 1 FROM orders o WHERE o.id=NEW.order_id AND o.origin='Live' AND o.actor<>'cliente')) AND p.price_cents=NEW.price_cents AND p.id=NEW.product_id);
END;
