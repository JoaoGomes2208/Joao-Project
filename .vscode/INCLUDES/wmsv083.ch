#ifdef SPANISH
	#define STR0001 "Genera Pedido Cross"
	#define STR0002 "Almac�n"
	#define STR0003 "Ubicaci�n"
	#define STR0004 "�Confirma la salida?"
	#define STR0005 "�Almac�n inv�lido!"
	#define STR0006 "�Ubicaci�n inv�lida!"
	#define STR0007 "Ubicaci�n no es del tipo crossdocking."
	#define STR0008 "Informe el volumen"
	#define STR0009 "En la ubicaci�n informada no existe ning�n volumen montado para generar pedido."
	#define STR0010 "�tems volumen"
	#define STR0011 "El volumen informado pertenece a un montaje de volumen de expedici�n."
	#define STR0012 "El volumen informado se est� utilizando en otro almac�n/ubicaci�n."
	#define STR0013 "Volumen informado inv�lido."
	#define STR0014 "Lista vol�menes"
	#define STR0015 "Agregue estos productos a vol�menes en la selecci�n."
	#define STR0016 "El volumen informado se encuentra en la lista."
	#define STR0017 "No existen vol�menes informados en la lista."
	#define STR0018 "Reversi�n Vol. Lista"
	#define STR0019 "El volumen informado no se encuentra en la lista."
	#define STR0020 "Procesando..."
	#define STR0021 "Generando pedido..."
	#define STR0022 "Ejecutando WMS..."
	#define STR0023 "Se gener� el pedido de venta:"
	#define STR0024 "Productos pendientes"
	#define STR0025 "Existen componentes faltantes para completar un producto en la selecci�n de vol�menes."
	#define STR0026 "Informe Cliente/Tienda"
	#define STR0027 "�Confirma la anulaci�n del proceso?"
	#define STR0028 "Anular"
	#define STR0029 "Confirmar"
	#define STR0030 "Cliente/Tienda no se registr� (SA1)."
	#define STR0031 "Condici�n de pago no se inform� para el Cliente/Tienda (SA1)."
	#define STR0032 "El servicio informado debe tener la funci�n de separaci�n cross-docking en la primera tarea."
	#define STR0033 "El servicio informado no puede tener tarea de verificaci�n de salida."
	#define STR0034 "El servicio informado no puede tener distribuci�n de separaci�n."
	#define STR0035 "El servicio informado debe tener montaje de vol�menes."
	#define STR0036 "El servicio informado no debe ser ejecuci�n autom�tica en la integraci�n. Este se ejecutar� por la rutina actual."
	#define STR0037 "Ocurrieron problemas al ejecutar las �rdenes de servicio del pedido."
	#define STR0038 "No fue posible encontrar el montaje de vol�menes del pedido."
	#define STR0039 "Ocurren problemas al intentar generar el pedido de venta."
	#define STR0040 "Cliente/Tienda no est� activo (SA1)."
	#define STR0041 "El valor de los par�metros MV_WMSTPOP (Tipo operaci�n pedido Cross-Docking) o MV_WMSTMCR (TES Pedido Cross-Docking) deben completarse."
	#define STR0042 "No fue posible efectuar toda la liberaci�n del �tem [VAR01] del pedido. Solicitado [VAR02] -> Liberado [VAR03]."
	#define STR0043 "Producto [VAR01] no tiene registro de saldo en el almac�n. (SB2)"
	#define STR0044 "El valor del costo medio unitario para el producto [VAR02] est� en cero. (SB2)"
	#define STR0045 "�Confirma la generaci�n del pedido de venda a partir de vol�menes?"
	#define STR0046 "Generar pedido"
	#define STR0047 "Cliente/Tienda [VAR01]/[VAR02] con bloqueo de cr�dito."
	#define STR0048 "Producto [VAR01] incluido en el pedido con bloqueo de stock, Verifique par�metros de liberaci�n del pedido."
#else
	#ifdef ENGLISH
		#define STR0001 "It Creates Cross Order"
		#define STR0002 "Warehouse"
		#define STR0003 "Address"
		#define STR0004 "Confirm exit?"
		#define STR0005 "Warehouse not valid!"
		#define STR0006 "Address not valid!"
		#define STR0007 "Address is not of crossdocking type."
		#define STR0008 "Enter volume"
		#define STR0009 "In the address entered, no volume assembled to create order exists."
		#define STR0010 "Volume Items"
		#define STR0011 "The volume entered belongs to a dispatch volume assembly."
		#define STR0012 "The volume entered is in use in another warehouse/address."
		#define STR0013 "Entered volume not valid!"
		#define STR0014 "Volumes List"
		#define STR0015 "Add these products to volumes in the selection."
		#define STR0016 "The volume entered is already in the list."
		#define STR0017 "No volumes entered in list."
		#define STR0018 "List Vol. Reversal"
		#define STR0019 "The volume entered is not in the list."
		#define STR0020 "Processing..."
		#define STR0021 "Generating Order..."
		#define STR0022 "Running WMS..."
		#define STR0023 "Sales order generated:"
		#define STR0024 "Pending Products"
		#define STR0025 "Some components to complete a product in volumes section are missing."
		#define STR0026 "Enter Client/Store"
		#define STR0027 "Confirm process cancellation?"
		#define STR0028 "Cancel"
		#define STR0029 "Confirm"
		#define STR0030 "Customer/Store not registered (SA1)."
		#define STR0031 "Payment term not entered for Customer/Store (SA1)."
		#define STR0032 "The service entered must have the function of cross-docking separation in first task."
		#define STR0033 "The service entered cannot have outflow checking task."
		#define STR0034 "The service entered cannot have separation distribution."
		#define STR0035 "The service entered cannot have volumes assembly."
		#define STR0036 "The service entered cannot be automatic execution in integration. The current routine will execute it."
		#define STR0037 "Problems occurred when running service orders of request."
		#define STR0038 "Could not find volumes assembly of order."
		#define STR0039 "Problems occurred in attempt to create sales order."
		#define STR0040 "Customer/Store not active (SA1)."
		#define STR0041 "You must fill out the value of parameter MV_WMSTPOP (Cross-Docking Order Operation Type) or MV_WMSTMCR (Cross-Docking Order TIO)."
		#define STR0042 "Could not fully release item [VAR01] of order. Requested [VAR02] -> Released [VAR03]."
		#define STR0043 "Product [VAR01] has no balance record in warehouse. (SB2)"
		#define STR0044 "Value of average unit cost for product [VAR02] is zeroed. (SB2)"
		#define STR0045 "Confirm creation of sales order from selection of volumes?"
		#define STR0046 "Create Order"
		#define STR0047 "Customer/Store [VAR01]/[VAR02] with credit block."
		#define STR0048 "Product [VAR01] added to order with stock block. Check parameters of order release."
	#else
		#define STR0001 "Gera Pedido Cross"
		#define STR0002 "Armazem"
		#define STR0003 "Endereco"
		#define STR0004 "Confirma a sa�da?"
		#define STR0005 "Armazem inv�lido!"
		#define STR0006 "Endere�o inv�lido!"
		#define STR0007 "Endere�o n�o � o do tipo crossdocking."
		#define STR0008 "Informe o Volume"
		#define STR0009 "No endere�o informado n�o existe nenhum volume montado para gerar pedido."
		#define STR0010 "Itens Volume"
		#define STR0011 "O volume informado pertence a uma montagem de volume de expedi��o."
		#define STR0012 "O volume informado est� sendo usado em outro armaz�m/endere�o."
		#define STR0013 "Volume informado inv�lido."
		#define STR0014 "Lista Volumes"
		#define STR0015 "Adicione estes produtos a volumes na sele��o."
		#define STR0016 "O volume informado j� se encontra na listagem."
		#define STR0017 "N�o existem volumes informados na listagem."
		#define STR0018 "Estorno Vol. Lista"
		#define STR0019 "O volume informado n�o se encontra na listagem."
		#define STR0020 "Processando..."
		#define STR0021 "Gerando Pedido..."
		#define STR0022 "Executando WMS..."
		#define STR0023 "Gerado o pedido de venda:"
		#define STR0024 "Produtos Pendentes"
		#define STR0025 "Existem componentes faltantes para completar um produto na sele��o de volumes."
		#define STR0026 "Informe Cliente/Loja"
		#define STR0027 "Confirma o cancelamento do processo?"
		#define STR0028 "Cancelar"
		#define STR0029 "Confirmar"
		#define STR0030 "Cliente/Loja n�o cadastrado (SA1)."
		#define STR0031 "Condi��o de pagamento n�o informada para o Cliente/Loja (SA1)."
		#define STR0032 "O servi�o informado deve possuir a fun��o de separa��o cross-docking na primeira tarefa."
		#define STR0033 "O servi�o informado n�o pode possuir tarefa de confer�ncia de sa�da."
		#define STR0034 "O servi�o informado n�o pode possuir distribui��o de separa��o."
		#define STR0035 "O servi�o informado deve possuir montagem de volumes."
		#define STR0036 "O servi�o informado n�o deve ser execu��o autom�tica na integra��o. O mesmo ser� executado pela rotina atual."
		#define STR0037 "Ocorreram problemas ao executar as ordens de servi�o do pedido."
		#define STR0038 "N�o foi poss�vel encontrar a montagem de volumes do pedido."
		#define STR0039 "Ocorrem problemas na tentativa de gerar o pedido de venda."
		#define STR0040 "Cliente/Loja n�o est� ativo (SA1)."
		#define STR0041 "O valor dos par�metros MV_WMSTPOP (Tipo Opera��o Pedido Cross-Docking) ou MV_WMSTMCR (TES Pedido Cross-Docking) devem ser preenchidos."
		#define STR0042 "N�o foi poss�vel efetuar toda a libera��o do item [VAR01] do pedido. Solicitado [VAR02] -> Liberado [VAR03]."
		#define STR0043 "Produto [VAR01] n�o possui registro de saldo no armaz�m. (SB2)"
		#define STR0044 "O valor do custo m�dio unit�rio para o produto [VAR02] est� zerado. (SB2)"
		#define STR0045 "Confirma gera��o do pedido de venda a partir da sele��o de volumes?"
		#define STR0046 "Gerar Pedido"
		#define STR0047 "Cliente/Loja [VAR01]/[VAR02] com bloqueio de cr�dito."
		#define STR0048 "Produto [VAR01] incluido no pedido com bloqueio de estoque, Verifique par�metros de libera��o do pedido."
	#endif
#endif