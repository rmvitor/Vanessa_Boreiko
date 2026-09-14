CREATE TABLE `coupons` (
	`id` text PRIMARY KEY NOT NULL,
	`code` text NOT NULL,
	`kind` text NOT NULL,
	`value` integer NOT NULL,
	`expires` text NOT NULL,
	`active` integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `coupons_code_unique` ON `coupons` (`code`);--> statement-breakpoint
CREATE TABLE `kit_items` (
	`id` text PRIMARY KEY NOT NULL,
	`kit_id` text NOT NULL,
	`product_id` text NOT NULL,
	FOREIGN KEY (`kit_id`) REFERENCES `kits`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `kit_items_kit` ON `kit_items` (`kit_id`);--> statement-breakpoint
CREATE TABLE `kits` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`active` integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE TABLE `order_discounts` (
	`order_id` text PRIMARY KEY NOT NULL,
	`code` text NOT NULL,
	`amount_cents` integer NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
DROP TRIGGER validate_order;
--> statement-breakpoint
CREATE TRIGGER validate_order BEFORE UPDATE OF status ON orders WHEN NEW.status='novo' AND OLD.status='draft' BEGIN
 SELECT RAISE(ABORT,'Estoque ou preço alterado. Atualize o carrinho e tente novamente.') WHERE NEW.expected_count<>(SELECT COUNT(*) FROM order_items WHERE order_id=NEW.id) OR NEW.total_cents<>COALESCE((SELECT SUM(price_cents) FROM order_items WHERE order_id=NEW.id),0)-COALESCE((SELECT amount_cents FROM order_discounts WHERE order_id=NEW.id),0);
END;
