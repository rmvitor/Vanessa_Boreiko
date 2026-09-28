# Vanessa Boreiko Acessórios

## Versão atual

Vitrine com preços de exemplo editáveis, carrinho, checkout sem conta obrigatória, pedidos persistidos e administração com login ChatGPT. D1 e R2 da hospedagem substituem a dependência pendente do Supabase; a migration PostgreSQL anterior foi mantida somente como referência, sem execução nesta versão.

### Rotas

- `/`: catálogo com busca, categorias, preços, disponibilidade, detalhes e sacola.
- `/admin`: produtos, preços, estoque, pedidos, clientes, categorias, grupos, histórico e configurações.
- `/api/catalog`: dados comerciais e disponibilidade agregada, sem custos.
- `/api/orders`: criação transacional e consulta do comprovante por token aleatório.
- `/api/admin`: leitura e alterações autorizadas no servidor.
- `/api/upload` e `/api/images/[key]`: imagens em R2.

### Dados e comportamento

Schema Drizzle em `db/schema.ts`; migrations versionadas em `drizzle/`. Tabelas: categories, sales_groups, products, product_images, product_items, stock_movements, customers, orders, order_items e settings. IDs técnicos UUID, códigos amigáveis VB por sequência. Valores monetários inteiros em centavos no banco.

Sete produtos com fotos fornecidas, preços fictícios de R$ 29,90 a R$ 89,90 e uma peça cada são cadastrados uma única vez. O bootstrap é idempotente e não sobrescreve preços, nomes ou estoque alterados. São dados iniciais para revisão, não alegações de estoque real.

Cada peça tem identidade própria. Cadastro de quantidade N cria N peças. Cadastro rápido cria um modelo/peça por foto. Reposição cria peças adicionais; inativação só atua sobre peças disponíveis. Entradas e mudanças de status geram histórico por triggers.

A sacola é um rascunho local, sem reservar estoque. Ao enviar o pedido, o servidor valida preços e disponibilidade dentro de uma transação, associa as peças e inicia a reserva (30 minutos, configurável). Quantidade insuficiente, preço alterado ou tentativa concorrente desfazem o pedido inteiro. A chave de idempotência evita repetição do mesmo envio. Endereço separado é obrigatório apenas na opção Entrega.

Reservas vencidas são liberadas na próxima consulta de catálogo, pedidos ou administração — não há execução agendada em segundo plano. Confirmação ou pagamento transforma reserva em venda. Cancelamento permitido antes do envio libera estoque; um pedido pago exige registro prévio de estorno. Confirmar pagamento não cobra dinheiro nem executa estorno bancário. Pedidos mantêm os preços registrados, mesmo que o catálogo seja alterado.

O cliente vê o número e pode recuperar o último comprovante no mesmo navegador. A consulta por token mostra itens, valores e status, sem endereço ou telefone. Clientes com o mesmo WhatsApp são agrupados. Frete e pagamento são combinados com a loja, sem gateway ou cálculo de transporte.

### Acesso

O login usa os helpers oficiais de ChatGPT em `app/chatgpt-auth.ts`. `lib/auth.ts` limita a administração à conta proprietária identificada no serviço de Sites. Uma conta ChatGPT qualquer não recebe acesso administrativo. O simulador local Seedy só é aceito em modo development; a publicação usa o login verdadeiro e a autorização do servidor. O site permanece privado ao proprietário até pedido explícito de mudança de público.

### Componentes

`storefront`, `cart`, `admin`, `product-form`, `order-detail` e `choice`, usando os primitives existentes de dialog, sheet, tabs, select, radio-group, switch e table. O tema da marca e as fotos originais foram preservados.

## Executar localmente

Node.js 22.13+ e npm:

```sh
npm ci
npm run dev
```

Configure um arquivo Wrangler local com binding DB, database_id `00000000-0000-4000-8000-000000000000`, database_name `site-creator-d1` e migrations_dir apontando para `drizzle`. Execute:

```sh
npx wrangler d1 migrations apply DB --local --config .wrangler/migrate.json --persist-to .wrangler/state
```

Acesse `http://localhost:5173`. O botão Entrar com ChatGPT usa o simulador local da hospedagem. No site publicado, usa a conta real.

```sh
npx tsc --noEmit
npm run build
node tests/integration.mjs
node tests/reservation.mjs
```

O teste de integração exige a prévia local e migrations aplicadas. Cria fixtures somente no banco local, ocultando o produto ao terminar. Testa autorização, adulteração de preço, corrida pela última peça, rollback, reenvio idempotente, comprovante, preço histórico, pagamento, estorno, cancelamento, agrupamento de clientes e restrições de upload. O teste de reserva verifica triggers e expiração em SQLite isolado.

## Limites e próximas etapas

Sem cobrança automática, notificações automáticas ou mensagens enviadas. Confirmar um pedido ou pagamento é uma operação administrativa, não uma transação bancária. Uploads abandonados podem deixar arquivos órfãos no R2. Listagem administrativa mostra os últimos 200 pedidos/clientes e 150 movimentos; paginação/exportação ampliada ficam para evolução.

Vendas presenciais/modo evento, financeiro operacional, consignações, etiquetas, relatórios avançados e portal de revendedoras são módulos posteriores do briefing. O filtro WebMCP anterior foi preservado; validação em ambiente WebMCP compatível continua pendente.

## Beta ampliada

A rota `/admin/operacoes` reúne venda manual, modo Evento, reserva de live, financeiro, relatórios CSV, revendedoras, consignações, acertos, repasses, cadastro manual de clientes, informações complementares/fotos de produtos, localização das peças, códigos de grupo, etiquetas, cupons e kits. Vendas individuais e consignações usam transações com validações no banco; vendas antigas por código de grupo permanecem no histórico. Novas vendas genéricas usam lotes com quantidade e baixa de estoque.

O catálogo inclui filtros por faixa de preço, cor, material, coleção, disponibilidade e novidades; favoritos locais; galeria; `/produto/[id]` compartilhável e QR Code. Cupons são validados no servidor, preservando o desconto no pedido. Kits agrupam produtos, sem eliminar sua identidade ou inventar estoque.

O portal `/revendedora` usa a conta ChatGPT vinculada ao e-mail do cadastro; somente a dona pode escolher uma revendedora para prévia. A audiência do Site continua privada ao proprietário. Cadastro de revendedora não concede acesso à hospedagem. PWA inclui manifesto e tela de indisponibilidade de conexão, sem armazenar dados privados ou permitir operações offline.

Migrations adicionais 0002–0005: vendas, linhas, despesas, revendedoras, consignações e acertos, repasses, detalhes de clientes e produtos, códigos rápidos, custos históricos, cupons, descontos, kits e origem dos pedidos. Migrations 0000/0001 publicadas permanecem intactas.

Validação: TypeScript, lint direcionado e testes `integration.mjs`, `reservation.mjs`, `operations.mjs`, `promotions.mjs`. Revisão local em largura de celular e geração de código de barras. Fixtures de testes existem apenas no banco local, não fazem parte do pacote publicado.

Limites da beta: confirmação de recebimento/estorno é manual, sem movimentação bancária; mensagens automáticas e notificações push externas não estão conectadas. Leitura de código funciona por câmera (com permissão em HTTPS) ou leitor em modo teclado. A câmera requer validação no celular real; a revisão local cobre a interface e a entrada por código. Impressão usa o navegador, sem integração de driver térmico. Relatórios indicam custos ausentes (pedidos legados e vendas de grupo); custos e preços dos novos itens são preservados, mas categorias e grupos dos pedidos de catálogo refletem o cadastro atual. Relatórios de consignação preservam valor e comissão no acerto. Reservas expiram na próxima consulta. A ativação pública e integrações comerciais dependem da decisão sobre continuidade do projeto.

## Atualização de lotes e caixa mobile

- /vendas: caixa exclusivo Live & Evento, busca e leitura de códigos VB e LOT, resumo móvel e venda ou reserva.
- /admin/operacoes?tab=lotes: cadastro e reposição de lotes genéricos com quantidade real. Cada unidade participa das mesmas transações de estoque. Lotes começam ocultos no catálogo.
- Fotos são otimizadas no navegador, com prévia, progresso e reenvio idempotente. Cadastro rápido usa lote SQL atômico.
- Links de gestão preservam a aba na URL. Adicionar ao carrinho mostra confirmação sem abri-lo.
- Migration 0006 adiciona lotes e chaves de cadastro; testes em tests/lots-photos.mjs cobrem concorrência, cancelamentos, reservas e cadastro de 30 fotos.


## Disponibilidade e lotes (setembro/2026)

Produtos e lotes usam seleção múltipla de disponibilidade: Evento, Live, Site e Consignado. Os canais compartilham o saldo. Catálogo público e operações validam a disponibilidade no servidor, inclusive contra requisições manuais. Os cadastros existentes preservam a visibilidade anterior no Site; os demais canais permanecem habilitados para revisão administrativa.

Em `/admin?tab=produtos`, produtos individuais ficam separados de `/admin?tab=lotes`. Lotes podem começar vazios, receber entradas, alterar nome/categoria/preços/finalidade/canais e transferir quantidades disponíveis. O destino define preços e canais futuros; preços históricos não são alterados. Transferências são atômicas, idempotentes e auditadas. Reservas e consignações não podem ser transferidas. A interface de lotes usa quantidade agregada; registros internos mantêm a rastreabilidade do estoque existente. Consignações permitem envio e acerto de lotes por quantidade.

Em `/vendas`, as abas Nova venda e Vendas registradas funcionam no celular. Há seleção de Evento/Live e categoria, busca de vendas por código, cliente ou data e detalhes/cancelamento. A busca de histórico mostra até 50 resultados por consulta.

Apagar produtos e pedidos faz exclusão recuperável. Produtos com reservas ou consignações não podem ser excluídos; os demais saem do catálogo e das vendas. A restauração fica em Mostrar excluídos/Lotes excluídos. Pedidos pendentes são cancelados na exclusão e liberam o estoque; pedidos pagos pendentes exigem estorno registrado. Pedidos enviados/entregues podem ser ocultados sem desfazer a venda. Restaurar um pedido não reabre a reserva. O histórico financeiro e de estoque é preservado.

Migrations 0007 e 0008 adicionam disponibilidade, exclusão, transferências e proteção contra mudança de lote durante a venda. Testes em `tests/channels-lots.mjs` cobrem canais, concorrência, transferência, consignação por quantidade, exclusão/restauração e pagamento. Verificações de interface usam prévia local, sem cadastrar testes em produção.
