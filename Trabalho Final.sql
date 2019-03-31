drop table comentario;
drop table compras_cliente;
drop table tipoproduto;
drop table clientes;
drop table mensagens;
drop table produtosAlterados;
drop table prod_semstock;
drop table lucroobtido;

--Adicionar as tabelas novas no ER
create table tipoproduto--criado
(cod_produto number(10) primary key,
nome_produto varchar(150) not null,
preco_venda number(10,2) check(preco_venda > 0),
descricao varchar(200),
quantidade number(30,2)
);

create table clientes
(cod_clientes number(7) primary key,
nome_cliente varchar(100) not null,
morada_cliente varchar(150) not null,
telefone number(12) not null,
local_entrega varchar(150) not null,
e_mail varchar(75) not null,
num_contribuinte number(9) not null,
username varchar(50),
pass varchar(20)
);

create table compras_cliente--criado
(cod_compra_cli number(10) primary key,
cod_produto number(10),
cod_cliente number(7),
quantidade number(4) check (quantidade > 0),
data_compra_cli date not null,
preco_venda number(6,2) check (preco_venda > 0),
foreign key (cod_produto) references tipoproduto (cod_produto),
foreign key (cod_cliente) references clientes (cod_clientes));

create table comentario
(cod_comentario number(5) primary key,
cod_clientes number(7),
cod_compra_cli number(10),
data_comentario date not null,
comentario varchar(250) not null,
foreign key(cod_clientes) references clientes(cod_clientes),
foreign key(cod_compra_cli) references compras_cliente(cod_compra_cli));

------------------------------------------------------
-- ??

--------------------------------------------------------------
drop sequence auto_increment2;
create sequence auto_increment2
minvalue 1
start with 1
increment by 1;

drop sequence seq_tipoproduto;
--Sequencia para tabela tipoproduto
create sequence seq_tipoproduto
minvalue 1
start with 1
increment by 1;

create or replace procedure desconto_dez_por_cento
is
CURSOR cproduto IS SELECT cod_produto,preco_venda FROM tipoproduto for update;
begin
FOR cp IN cproduto
LOOP
update tipoproduto set  cod_produto = cod_produto , preco_venda = preco_venda*0.9 where current of cproduto;
END LOOP;
end;

/

create OR REPLACE procedure atualizar_cliente
(nome in varchar, morada in varchar, tele in number, local_var in varchar, mail in varchar, nif in number, x out number)
is
begin 
update clientes
set nome_cliente = nome, morada_cliente=morada, telefone=tele, local_entrega=local_var, e_mail=mail 
where num_contribuinte = nif;
x := sql%rowcount;
end;
/


create or replace procedure inserir_produto(nome in varchar, preco in number, des in varchar, quan in number)
is
begin 
insert into tipoproduto (cod_produto, nome_produto,preco_venda,descricao ,quantidade) values (auto_increment2.nextval ,nome, preco, des, quan);
end;
--/

--create or replace procedure adiciona_produto (vproduto IN number, vnome IN number, vpreco IN number, vdescricao IN number, vquantidade IN number)
--IS
--x int;
--Begin
    --insert into tipoproduto values (vproduto, vnome, vpreco, vdescricao, vquantidade);
    --x := sql%rowcount;
--End;

/

create or replace procedure inserir_cliente(nome in varchar, morada in varchar, tele in number, local_var in varchar, mail in varchar, nif in number, x out number)
is
begin 
insert into clientes (cod_clientes, nome_cliente,morada_cliente,telefone,local_entrega,e_mail,num_contribuinte) values (auto_increment2.nextval ,nome, morada, tele, local_var, mail, nif);
x := sql%rowcount;
end;
/
create or replace function remove_cliente (nif in number)
return number
IS
x number;
Begin
    Delete from clientes where num_contribuinte = nif;
    x := sql%rowcount;
    return x;
End;

  /
create or replace procedure remove_produto (id_produto IN number, x out number)
IS
Begin
    Delete from tipoproduto where cod_produto  = id_produto;
    x := sql%rowcount;
End;
/
create or replace procedure efetuar_compra (cod_clientes In number, cod_produto In number, quantidade IN number, preco IN number, x OUT number)
IS
Begin
  insert into compras_cliente(cod_compra_cli, cod_produto, cod_cliente, quantidade, data_compra_cli, preco_venda) values (auto_increment2.nextval,cod_clientes, cod_produto, quantidade, CURRENT_DATE, preco);
End;
/
create table mensagens
(tempmsg varchar(200)
);
drop sequence seq_tipoproduto;
--Sequ?ncia para tabela tipoproduto
create sequence seq_tipoproduto
start with 1 increment by 1;

--select * from tipoproduto;
drop sequence seq_clientes;
DROP sequence seq_compras_cliente;
create sequence seq_clientes start with 1 increment by 1;
 create sequence seq_compras_cliente start with 1 increment by 1;

    

  /
  
  --Triggers

create or replace trigger registoCompras
before insert on compras_cliente
for each row
declare
v_codcompra compras_cliente.cod_compra_cli%type;
v_codproduto compras_cliente.cod_produto%type;
v_codcliente compras_cliente.cod_cliente%type;
v_data compras_cliente.data_compra_cli%type;
s varchar2(200);
BEGIN
v_codcompra := :new.cod_compra_cli;
v_codproduto := :new.cod_produto;
v_codcliente  := :new.cod_cliente; 
v_data := :new.data_compra_cli;

s:= 'Registo numero: ' || v_codcompra || 'do cliente numero:' || v_codcliente || 'produto adquirido numero:' || v_codproduto 
|| 'na data: ' || v_data;
insert into mensagens (tempmsg) values (s);
END;

/

create table produtosAlterados(
cod_produto number(10,0),
nome_produto varchar2(150),
preco_venda number(4,2),
observacoes varchar2(200)
);

/

create or replace trigger updatePrecosProdutos 
after update on tipoproduto
for each row
declare
 novopreco number(7,2);
 codprod number(4);
 nomeprod varchar2(150);
begin
 novopreco:= :new.preco_venda;
 codprod:=:new.cod_produto;
 nomeprod:= :new.nome_produto;
 if :old.preco_venda<>:new.preco_venda then
 insert into produtosAlterados (cod_produto, nome_produto, preco_venda, observacoes)
 values (codprod, nomeprod, novopreco, 'Foi alterado o Preço');
 end if;
end; 

/

create table prod_semstock
(cod_produto number(10),
nome_produto varchar(100),
preco_venda number(7,2)
); 

--select * from tipoproduto;
create or replace trigger produtofstock 
after update of quantidade on tipoproduto
for each row
declare
 novo_produto number;
 novo_preco number;
 novo_nome varchar2(150);
 nova_quantidade number(30,2);
 BEGIN
 novo_produto := :new.cod_produto;
 novo_nome := :new.nome_produto;
 novo_preco := :new.preco_venda;
 nova_quantidade := :new.quantidade;

 if(nova_quantidade = 0) then 
  insert into prod_semstock (cod_produto,nome_produto,preco_venda)
    values (novo_produto,novo_nome, novo_preco);
 end if;
end;

/


create table lucroobtido(
datacompra date,
lucro number(30),
descricao varchar2(200)
);

/

create or replace trigger lucro
after update of quantidade on tipoproduto
for each row
when (new.quantidade <> old.quantidade)
declare 
  lucroobtido number(30);
  descricaoproduto varchar2(250);
BEGIN 
  lucroobtido := :new.preco_venda;
  descricaoproduto := :new.descricao;
  insert into lucroobtido (datacompra, lucro, descricao)
  values (sysdate, lucroobtido, descricaoproduto);
END;


/

create or replace procedure verifica_produto
(id_produto IN number, k OUT number)
IS

Begin
  select cod_produto into k from tipoproduto where cod_produto = id_produto;
End;

/

--verifica cliente
create or replace procedure verifica_cliente
(id_cliente IN number, w OUT number)
IS

Begin
  select cod_clientes into w from clientes where cod_clientes = id_cliente;
End;  

/

create or replace procedure verifica_comentario
(id_comentario IN number, id_cliente IN number, id_compra_cli IN number ,y OUT number)
IS
k comentario%rowtype;
Begin
  select * into k from comentario where cod_comentario = id_comentario;
End;

