const payments:Record<string,string>={pix:'Pix',dinheiro:'Dinheiro',credito:'Cartão de crédito',debito:'Cartão de débito',outro:'Outro',pendente:'Pendente'};
export const paymentLabel=(value:string)=>payments[value]||value;
export const paymentOptions=Object.entries(payments).filter(([id])=>id!=='pendente').map(([id,name])=>({id,name}));
export const saleStatusLabel=(value:string)=>({concluida:'Concluída',cancelada:'Cancelada'} as Record<string,string>)[value]||value;
