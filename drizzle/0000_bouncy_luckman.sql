CREATE TABLE `categories` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `categories_name_unique` ON `categories` (`name`);--> statement-breakpoint
CREATE TABLE `customers` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`phone` text NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL
);
--> statement-breakpoint
CREATE TABLE `sales_groups` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX `sales_groups_name_unique` ON `sales_groups` (`name`);--> statement-breakpoint
CREATE TABLE `product_images` (
	`id` text PRIMARY KEY NOT NULL,
	`product_id` text NOT NULL,
	`url` text NOT NULL,
	`position` integer DEFAULT 0 NOT NULL,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `images_product` ON `product_images` (`product_id`);--> statement-breakpoint
CREATE TABLE `stock_movements` (
	`id` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`item_id` text NOT NULL,
	`type` text NOT NULL,
	`actor` text NOT NULL,
	`reason` text NOT NULL,
	`reference` text,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`item_id`) REFERENCES `product_items`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `order_items` (
	`id` text PRIMARY KEY NOT NULL,
	`order_id` text NOT NULL,
	`item_id` text NOT NULL,
	`product_id` text NOT NULL,
	`name` text NOT NULL,
	`image` text NOT NULL,
	`price_cents` integer NOT NULL,
	FOREIGN KEY (`order_id`) REFERENCES `orders`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`item_id`) REFERENCES `product_items`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE INDEX `order_items_order` ON `order_items` (`order_id`);--> statement-breakpoint
CREATE UNIQUE INDEX `order_piece_once` ON `order_items` (`order_id`,`item_id`);--> statement-breakpoint
CREATE TABLE `orders` (
	`seq` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`id` text NOT NULL,
	`request_key` text NOT NULL,
	`receipt_hash` text NOT NULL,
	`customer_id` text NOT NULL,
	`name` text NOT NULL,
	`phone` text NOT NULL,
	`delivery` text NOT NULL,
	`cep` text DEFAULT '' NOT NULL,
	`street` text DEFAULT '' NOT NULL,
	`number` text DEFAULT '' NOT NULL,
	`complement` text DEFAULT '' NOT NULL,
	`neighborhood` text DEFAULT '' NOT NULL,
	`city` text DEFAULT '' NOT NULL,
	`state` text DEFAULT '' NOT NULL,
	`reference` text DEFAULT '' NOT NULL,
	`notes` text DEFAULT '' NOT NULL,
	`status` text DEFAULT 'draft' NOT NULL,
	`payment` text DEFAULT 'aguardando' NOT NULL,
	`payment_method` text DEFAULT 'a_combinar' NOT NULL,
	`expected_count` integer NOT NULL,
	`total_cents` integer NOT NULL,
	`expires_at` text,
	`actor` text DEFAULT 'cliente' NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`customer_id`) REFERENCES `customers`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `orders_id_unique` ON `orders` (`id`);--> statement-breakpoint
CREATE UNIQUE INDEX `orders_request_key_unique` ON `orders` (`request_key`);--> statement-breakpoint
CREATE INDEX `orders_expiry` ON `orders` (`status`,`expires_at`);--> statement-breakpoint
CREATE INDEX `orders_customer` ON `orders` (`customer_id`);--> statement-breakpoint
CREATE TABLE `product_items` (
	`seq` integer PRIMARY KEY AUTOINCREMENT NOT NULL,
	`id` text NOT NULL,
	`product_id` text NOT NULL,
	`status` text DEFAULT 'disponivel' NOT NULL,
	`group_id` text,
	`location` text DEFAULT 'Loja' NOT NULL,
	`actor` text DEFAULT 'sistema' NOT NULL,
	`reason` text DEFAULT 'Cadastro inicial' NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`product_id`) REFERENCES `products`(`id`) ON UPDATE no action ON DELETE no action,
	FOREIGN KEY (`group_id`) REFERENCES `sales_groups`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE UNIQUE INDEX `product_items_id_unique` ON `product_items` (`id`);--> statement-breakpoint
CREATE INDEX `items_product_status` ON `product_items` (`product_id`,`status`);--> statement-breakpoint
CREATE TABLE `products` (
	`id` text PRIMARY KEY NOT NULL,
	`name` text NOT NULL,
	`category_id` text NOT NULL,
	`price_cents` integer NOT NULL,
	`cost_cents` integer DEFAULT 0 NOT NULL,
	`color` text DEFAULT '' NOT NULL,
	`material` text DEFAULT '' NOT NULL,
	`description` text DEFAULT '' NOT NULL,
	`published` integer DEFAULT 1 NOT NULL,
	`created_at` text DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')) NOT NULL,
	FOREIGN KEY (`category_id`) REFERENCES `categories`(`id`) ON UPDATE no action ON DELETE no action
);
--> statement-breakpoint
CREATE TABLE `settings` (
	`key` text PRIMARY KEY NOT NULL,
	`value` text NOT NULL
);
--> statement-breakpoint
CREATE TRIGGER item_entry AFTER INSERT ON product_items BEGIN
 INSERT INTO stock_movements(item_id,type,actor,reason) VALUES(NEW.id,'entrada',NEW.actor,NEW.reason);
END;
--> statement-breakpoint
CREATE TRIGGER item_change AFTER UPDATE OF status ON product_items WHEN OLD.status<>NEW.status BEGIN
 INSERT INTO stock_movements(item_id,type,actor,reason,reference) VALUES(NEW.id,CASE NEW.status WHEN 'reservado' THEN 'reserva' WHEN 'vendido' THEN 'venda' WHEN 'disponivel' THEN 'devolucao' ELSE 'ajuste' END,NEW.actor,NEW.reason,(SELECT order_id FROM order_items WHERE item_id=NEW.id ORDER BY rowid DESC LIMIT 1));
END;
--> statement-breakpoint
CREATE TRIGGER protect_item_status BEFORE UPDATE OF status ON product_items WHEN NEW.status NOT IN ('disponivel','reservado','vendido','consignado','inativo') BEGIN SELECT RAISE(ABORT,'Status de estoque inválido'); END;
--> statement-breakpoint
CREATE TRIGGER order_item_available BEFORE INSERT ON order_items BEGIN
 SELECT CASE WHEN NOT EXISTS(SELECT 1 FROM product_items i JOIN products p ON p.id=i.product_id WHERE i.id=NEW.item_id AND i.status='disponivel' AND p.published=1 AND p.price_cents=NEW.price_cents AND p.id=NEW.product_id) THEN RAISE(ABORT,'Uma peça ficou indisponível ou teve o preço alterado. Atualize o carrinho.') END;
END;
--> statement-breakpoint
CREATE TRIGGER reserve_order_item AFTER INSERT ON order_items BEGIN
 UPDATE product_items SET status='reservado',actor='cliente',reason='Reserva do pedido '||NEW.order_id WHERE id=NEW.item_id;
END;
--> statement-breakpoint
CREATE TRIGGER validate_order BEFORE UPDATE OF status ON orders WHEN NEW.status='novo' AND OLD.status='draft' BEGIN
 SELECT CASE WHEN NEW.expected_count<>(SELECT COUNT(*) FROM order_items WHERE order_id=NEW.id) OR NEW.total_cents<>COALESCE((SELECT SUM(price_cents) FROM order_items WHERE order_id=NEW.id),0) THEN RAISE(ABORT,'Estoque ou preço alterado. Atualize o carrinho e tente novamente.') END;
END;
--> statement-breakpoint
CREATE TRIGGER order_transition BEFORE UPDATE OF status ON orders WHEN OLD.status<>NEW.status BEGIN
 SELECT CASE WHEN NOT ((OLD.status='draft' AND NEW.status='novo') OR (OLD.status='novo' AND NEW.status IN ('confirmado','cancelado','expirado')) OR (OLD.status='confirmado' AND NEW.status IN ('preparando','cancelado')) OR (OLD.status='preparando' AND NEW.status IN ('enviado','entregue','cancelado')) OR (OLD.status='enviado' AND NEW.status='entregue')) THEN RAISE(ABORT,'Transição de pedido inválida') END;
 SELECT CASE WHEN NEW.status IN ('cancelado','expirado') AND OLD.payment='pago' THEN RAISE(ABORT,'Registre o estorno antes de cancelar um pedido pago') END;
 SELECT CASE WHEN NEW.status IN ('enviado','entregue') AND NEW.payment<>'pago' THEN RAISE(ABORT,'Confirme o pagamento antes da entrega') END;
END;
--> statement-breakpoint
CREATE TRIGGER order_confirm AFTER UPDATE OF status ON orders WHEN NEW.status='confirmado' AND OLD.status='novo' BEGIN
 UPDATE product_items SET status='vendido',actor=NEW.actor,reason='Confirmação do pedido '||NEW.id WHERE id IN (SELECT item_id FROM order_items WHERE order_id=NEW.id) AND status='reservado';
END;
--> statement-breakpoint
CREATE TRIGGER order_release AFTER UPDATE OF status ON orders WHEN NEW.status IN ('cancelado','expirado') AND OLD.status<>NEW.status BEGIN
 UPDATE product_items SET status='disponivel',actor=NEW.actor,reason='Pedido '||NEW.status||' '||NEW.id WHERE id IN (SELECT item_id FROM order_items WHERE order_id=NEW.id) AND status IN ('reservado','vendido');
END;
