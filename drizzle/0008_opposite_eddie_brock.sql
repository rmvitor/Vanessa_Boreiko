ALTER TABLE `consignment_items` ADD `expected_product_id` text;--> statement-breakpoint
ALTER TABLE `sale_lines` ADD `expected_product_id` text;--> statement-breakpoint
CREATE TRIGGER sale_lot_identity BEFORE INSERT ON sale_lines WHEN NEW.expected_product_id IS NOT NULL BEGIN
 SELECT RAISE(ABORT,'O lote foi alterado. Atualize a venda.') WHERE NOT EXISTS(SELECT 1 FROM product_items WHERE id=NEW.item_id AND product_id=NEW.expected_product_id);
END;
--> statement-breakpoint
CREATE TRIGGER consign_lot_identity BEFORE INSERT ON consignment_items WHEN NEW.expected_product_id IS NOT NULL BEGIN
 SELECT RAISE(ABORT,'O lote foi alterado. Atualize a consignação.') WHERE NOT EXISTS(SELECT 1 FROM product_items WHERE id=NEW.item_id AND product_id=NEW.expected_product_id);
END;
--> statement-breakpoint
CREATE TRIGGER archived_product_entry BEFORE INSERT ON product_items BEGIN
 SELECT RAISE(ABORT,'Restaure o produto antes de adicionar estoque.') WHERE EXISTS(SELECT 1 FROM products WHERE id=NEW.product_id AND deleted_at IS NOT NULL);
END;
--> statement-breakpoint
CREATE TRIGGER archived_product_activation BEFORE UPDATE OF status ON product_items WHEN NEW.status='disponivel' BEGIN
 SELECT RAISE(ABORT,'Restaure o produto antes de reativar estoque.') WHERE EXISTS(SELECT 1 FROM products WHERE id=NEW.product_id AND deleted_at IS NOT NULL);
END;
