ALTER TABLE `resellers` ADD `email` text;--> statement-breakpoint
CREATE UNIQUE INDEX `resellers_email_unique` ON `resellers` (`email`);