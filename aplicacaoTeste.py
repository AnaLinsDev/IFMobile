import psycopg2 as pg
import random

#usua = input('Faca seu login: \nUsuário: ')
#senha = input('Senha: ')
try:
    con = pg.connect(
            host='localhost', 
            database= 'ifmobile', 
            user="postgres",
            password="postgres",
            port=5432)
except pg.DatabaseError as dbe:
    print('ERRO, NÃO FOI POSSIVEL CONECTAR AO BANCO\nVerifique se suas credenciais estão corretas, \nse o banco está criado ou em funcionamento.\nTipo: ', dbe)
    exit()

class List:
    def __init__(self, head=None):  # Construtor
        self._head = head
        self.res = False

    def geraNum(self, opera, plan):  
        try:
            cur = con.cursor()
            cur.execute("SELECT * FROM chip;")
            antigoresult = cur.fetchall()
            cur.execute("INSERT INTO chip (idOperadora, idPlano, ativo, disponivel) VALUES ( %s, %s, 'S', 'S');",(opera, plan))
            con.commit()
            cur.execute("SELECT * FROM chip;")
            result = cur.fetchall()
            lista_final = [x for x in result if x not in antigoresult]
            for x in lista_final:
                print("Número gerado: ")
                print( x[0])
            con.commit()

        except Exception as e:
            con.rollback()
            return print('Operação abortada!', type(e))

    def gera5NumDisp(self):
        cur = con.cursor() 
        cur.execute("SELECT * FROM verInativNum();")
        nums = cur.fetchall()
        print("Números disponiveis: ")
        for x in nums:
            print('Num: ', x[0], ' Disp: ',x[2] ,'Ati: ' ,x[1] )
        con.commit()

    def povoaLig(self): 
        cur = con.cursor()

        try:
            mes = int(input("Insira o mes: "))
            ano = int(input("Insira o ano: "))
        except ValueError:
            con.rollback()
            return print('Não é permitido caracteres que não sejam numeros!')

        try:
            cur.execute("CALL geraLig(%s, %s);", (mes, ano))
        except pg.errors.InvalidDatetimeFormat as e:
            con.rollback()
            return print("Datas inválidas, operação abortada!\nError tipo: {erType}".format(erType = type(e)))
        except pg.errors.DatetimeFieldOverflow as e2:
            con.rollback()
            return print("Houve um overflow da data(data fora do alcance), operação abortada!\nError tipo: {erType}".format(erType = type(e2)))
        except pg.errors.UniqueViolation as e3:
            con.rollback()
            return print("Já existem ligações nessa data, operação abortada!\nError tipo: {erType}".format(erType = type(e3)))
        except Exception as e:
            con.rollback()
            return print(e)
        con.commit()
        cur.execute("SELECT COUNT(*) FROM ligacao as li where EXTRACT(MONTH FROM li.data) = %s AND EXTRACT(YEAR FROM li.data) = %s", (mes,ano))
        result_novalig = cur.fetchall()
        print("ligação gerada: ")
        for row7 in result_novalig:
            print("Quantidade de ligações realizadas: "+str(row7[0])+"\n")
        con.commit()
    
    def viewUm(self):  
        cur = con.cursor()
        cur.execute("select * from rankPlan;")
        result_view1 = cur.fetchall()
        lista_view1 = [x for x in result_view1]
        print("Rank de planos: ")
        for row in lista_view1:
            print("idplano: ",row[0])
            print("descricao: ",row[1])
            print("quantidade: ",row[2])
            print("total: ",row[3])
            print("-----------")
        con.commit()

    def viewDois(self): 
        cur = con.cursor()
        cur.execute("select * from faturamento order by ano, mes;")
        result_view2 = cur.fetchall()
        lista_view2 = [x for x in result_view2]
        print("Faturamento por mes/ano: ")
        for row in lista_view2:
            print("ano: {:.0f}".format(row[0]))
            print("mes: {:.0f}".format(row[1]))
            print("Numero de Clientes: ",row[2])
            print("Faturamento: ",row[3])
            print("-----------")
        con.commit()

    def viewTres(self):
            cur = con.cursor()
            cur.execute("select * from fidelidade;")
            result_view3 = cur.fetchall()
            for row in result_view3:
                    print("idCliente:   ", row[0])
                    print("nome:        ", row[1])
                    print("uf:          ", row[2])
                    print("idnumero:    ", row[3])
                    print("idplano:     ", row[4])
                    print("tempo fiel:  ", row[5])
                    print("-----------")
            con.commit()

    def geraFatura(self):
        try:
            mes = int(input("Insira o mes: "))
            ano = int(input("Insira o ano: "))
        except ValueError:
            con.rollback()
            return print('Não é permitido caracteres que não sejam numeros!')
        cur = con.cursor()
        try:
            cur.execute("CALL geraFatu(%s, %s);", (mes, ano))
            con.commit()
        except pg.errors.UniqueViolation as e:
            con.rollback()
            return print("Já existe fatura nessa data, operação abortada!\nTipo :",type(e))
        cur.execute("SELECT * FROM fatura as fa WHERE EXTRACT(MONTH FROM fa.referencia) = %s AND EXTRACT(YEAR FROM fa.referencia) = %s;",(mes,ano))
        result_fatura = cur.fetchall()
        for row in result_fatura:
            print("data referencial: ", row[0])
            print("idnumero: ",row[1])
            print("valor plano: ",row[2])
            print("total minutos internos: ",row[3])
            print("total minutos externos: ",row[4])
            print("taxa minutos excedidos: ",row[5])
            print("taxa roaming: ",row[6])
            print("total: ",row[7])
            print("pago: ",row[8] )
            print("===================" )

    def negLigInat(self): 
        cur = con.cursor()
        temp = []
        cur.execute("SELECT idNumero FROM chip where ativo = 'N' LIMIT 5;") 
        result_inativos = cur.fetchall()
        cont = 1
        print("Números inativos: ")
        for row3 in result_inativos:
            print('{} - {}'.format(cont, row3[0]))
            temp.append(row3[0])
            cont+=1
            

        cur.execute("SELECT idNumero FROM chip where ativo = 'S'LIMIT 5;") 
        result_ativos = cur.fetchall()

        print("Números ativos: ")
        for row2 in result_ativos:
            print('{} - {}'.format(cont, row2[0]))
            temp.append(row2[0])
            cont+=1

        emissor = int(input("Escolha o índice ao lado do número que irá ligar: "))
        receptor = int(input("Escolha o índice ao lado do número que irá receber a ligação: "))
        dia = random.randint(1,23)
        minu = random.randint(1,23)
        dia = int(format(dia, '02'))
        minu = int(format(minu, '02'))
        

        try:
            cur.execute("insert into ligacao (data, chip_emissor, ufOrigem, chip_receptor, ufDestino, duracao) values ('2001-07-%s 21:%s:00',%s, 'PB', %s, 'PB', '0:52:06');",(dia, minu, temp[emissor-1], temp[receptor-1]))
            con.commit()
            print('Ligacao adicionada !!\n',)
        except pg.errors.RaiseException as e:
            con.rollback()
            return print('\nNão é possível fazer/receber ligações com um número inativo!\n', e)

        cur.execute("select * from ligacao where chip_emissor = %s and chip_receptor = %s and data = '2001-07-%s 21:%s:00';",(temp[emissor-1], temp[receptor-1], dia, minu))
        novaliga = cur.fetchall()

        for row in novaliga:
            print("data: ", row[0])
            print("emissor: ",row[1])
            print("uf origem: ",row[2])
            print("receptor:: ",row[3])
            print("uf destino: ",row[4])
            print("duracao: ",row[5])
        con.commit()
        

    def libChip(self): 
        cur = con.cursor()
        cur.execute ("SELECT idCliente, nome from cliente where cancelado = 'N' LIMIT 5;")
        result_naocanc1 = cur.fetchall()
        print("Clientes não cancelados: ")
        for row5 in result_naocanc1:
            print(row5)
        cliente1 = input("Qual cliente você deseja cancelar? Escolha o numero: ")
        try:
            cur.execute("SELECT chip.idnumero FROM cliente join cliente_chip on cliente_chip.idcliente = cliente.idcliente join chip on cliente_chip.idnumero = chip.idnumero WHERE cliente.idcliente = "+cliente1+";")
        except pg.errors.UndefinedColumn:
            con.rollback()
            return print('Não é permitido usar letras na escolha!')
            
        result_clch = cur.fetchall()
        if result_clch == []:
            con.rollback()
            return print ('Não existem numeros ativos para esse cliente! \nOu ele é um cliente novo ou está cancelado!')
            
        print("Números do cliente: ")
        for row6 in result_clch:
            print(row6)
        resposta = input("Tem certeza que quer fazer isso? S/N: ")
        if resposta.upper() == 'S':
            cur.execute("UPDATE cliente  SET cancelado = 'S' where idCliente = "+cliente1+";")
            con.commit()
            print("Agora números estão disponiveis! ")
        else:
            con.rollback()
            print('Operação cancelada!')

        

    def negChCliIna(self):
        cur = con.cursor()
        cur.execute ("SELECT idCliente, nome from cliente where cancelado = 'N' LIMIT 5;")
        result_naocanc = cur.fetchall()
        print("Clientes não cancelados: ")
        for row4 in result_naocanc:
            print('id: {} - nome: {}'.format(row4[0],row4[1]))
        cur.execute ("SELECT idCliente, nome from cliente where cancelado = 'S' LIMIT 5;")
        result_canc = cur.fetchall()
        print("Clientes Cancelados:")
        for row5 in result_canc:
            print('id: {} - nome: {}'.format(row5[0],row5[1]))
        cliente = input("Digite o seu idCliente: ")
        self.gera5NumDisp()
        numero = input("Digite o seu número: ")
        try:
            cur.execute("insert into cliente_chip (idNumero, idCliente) values ('"+numero+"', "+cliente+");")
            con.commit()
            print('Foi adicionado novo chip para o cliente !')
        except Exception as e:
            con.rollback()
            print('Não é possível atribuir chip !', type(e))

    def menu(self):
        print( """List
         0 - Fim
         1 - Geração de número
         2 - Geração de até 5 números disponiveis
         3 - Povoamento de ligacao  
         4 - View 1: Ranking planos
         5 - View 2: Faturamento por mes/ano
         6 - View 3: Detalhamento dos clientes
         7 - Negar ligação de numeros inativos/disponiveis
         8 - Liberar chip de cliente cancelado
         9 - Garante chip disponivel para cliente ativo
         10 - Gerar fatura
        """)

lis = List()
lis.menu()
r = input(" Type your choice: ")

while (r != '0'):
    if r == "1": #OK
        try:
            print("""Escolha A Operadora: \nDigite o numero 0 para sair.""")

            cur = con.cursor()
            cur.execute("SELECT * FROM operadora;")
            ope = cur.fetchall()

            for x in ope:
                print(x)

            opera = int(input('\n'))
            if opera == 0:
                con.rollback()
                raise Exception("Operação abortada")
            elif opera > 10 or opera < 0:
                con.rollback()
                raise ReferenceError()

            cur.execute("SELECT * FROM plano;")
            ope = cur.fetchall()

            for x in ope:
                print (str(x[0])+' - '+str(x[1]))
                print ('    Minutos p/ mesma operadora: '+str(x[2]))
                print ('    Minutos p/ outra operadora: '+str(x[3]))
                print ('    Valor: '+str(x[4]))

            plan = int(input ('Escolha o plano: \nDigite o numero 0 para sair.\n'))
            if plan == 0:
                con.rollback()
                raise Exception("Operação abortada")
            elif plan > 8 or opera < 0:
                con.rollback()
                raise ReferenceError()

            lis.geraNum(opera, plan)
        except ValueError:
            print('Opção inválida, por favor, digite somente números!')    
        except ReferenceError:
            print('Opção inválida!\n')
        except Exception as r:
                print('Operação abortada\n')
    elif r == "2":
        lis.gera5NumDisp() 
        
    elif r == "3": 
        lis.povoaLig() 
        
    elif r == "4":
        lis.viewUm()
        
    elif r == "5":
        lis.viewDois()

    elif r == "6":
        lis.viewTres()

    elif r == "7": 
        lis.negLigInat()

    elif r == "8": 
        lis.libChip()  

    elif r == "9": 
        lis.negChCliIna()

    elif r == "10": 
        lis.geraFatura()

    else:
        lis.menu()
    lis.menu()
    r = input(" Type your choice: ")
print('Banco Fechado, Fim !')
con.close()
