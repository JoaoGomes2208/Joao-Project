#ifdef SPANISH
	#define STR0001 "Optometria"
	#define STR0002 "Nombre del Cliente:"
	#define STR0003 "Optometria"
	#define STR0004 "Nombre del Medico:"
	#define STR0005 "Paciente: "
	#define STR0006 "Producto"
	#define STR0007 "Optometria - Lejos"
	#define STR0008 "Esferico"
	#define STR0009 "Cilindro"
	#define STR0010 "Eje"
	#define STR0011 "DNP"
	#define STR0012 "Altura"
	#define STR0013 "Pelicula"
	#define STR0014 "DP"
	#define STR0015 "OD"
	#define STR0016 "Optometria - Cerca"
	#define STR0017 "OI"
	#define STR0018 "Adicion"
	#define STR0019 "Srv Color"
	#define STR0020 "�Optometria "
	#define STR0021 " grabada con exito!"
	#define STR0022 "�Seleccione una lente generica!"
	#define STR0023 "�Producto no encontrado!"
	#define STR0024 "�CRM no registrado !"
	#define STR0025 "No hay lentes listas vinculadas al codigo "
	#define STR0026 " para el ojo "
	#define STR0027 "DERECHO"
	#define STR0028 "IZQUIERDO"
	#define STR0029 ". �Se analizaran bloques !"
	#define STR0030 "Lentes Listas no registradas"
	#define STR0031 "No hay bloques de Lentes vinculados al codigo "
	#define STR0032 ". � No es posible continuar !"
	#define STR0033 "Bloques no registrados"
	#define STR0034 "No hay Bloques que atiendan el Grado solicitado para el ojo "
	#define STR0035 "Bloques no atienden Dioptria"
	#define STR0036 "Lentes Listas para el olho "
	#define STR0037 "Bloques (Bases) para el olho "
	#define STR0038 "Seleccion de "
	#define STR0039 "Producto Digitado: "
	#define STR0040 "Consulta Stock: "
	#define STR0041 "OJO DERECHO"
	#define STR0042 "OJO IZQUIERDO"
	#define STR0043 "Dioptria: ESF "
	#define STR0044 " ; CIL "
	#define STR0045 "Adicion"
	#define STR0046 "Codigo                 Descripcion                                           Referencia                      Local     Actual Reserv.   Disp.  "
	#define STR0047 "Datos de la optometria"
	#define STR0048 "Optometria - Base"
	#define STR0049 "Observaciones de la optometria:"
#else
	#ifdef ENGLISH
		#define STR0001 "Optometry"
		#define STR0002 "Customer Name:"
		#define STR0003 "Optometry"
		#define STR0004 "Doctor Name:"
		#define STR0005 "Patient: "
		#define STR0006 "Product"
		#define STR0007 "Optometry - Far"
		#define STR0008 "Spherical"
		#define STR0009 "Cylindrical"
		#define STR0010 "Axle"
		#define STR0011 "DNP"
		#define STR0012 "Height"
		#define STR0013 "Film"
		#define STR0014 "DP"
		#define STR0015 "RE"
		#define STR0016 "Optometry - Close"
		#define STR0017 "LE"
		#define STR0018 "Addition"
		#define STR0019 "Color Srv"
		#define STR0020 "Optometry "
		#define STR0021 " successfull saved!"
		#define STR0022 "Select generic lens!"
		#define STR0023 "Product not found!"
		#define STR0024 "CRM not registered!"
		#define STR0025 "There are no ready lens associated with code"
		#define STR0026 " for the eye "
		#define STR0027 "RIGHT"
		#define STR0028 "LEFT"
		#define STR0029 ". Blocks will be analyzed!"
		#define STR0030 "Ready lens not registered"
		#define STR0031 "There are no blocks of lens associated with the code "
		#define STR0032 ". Continuing is not possible!"
		#define STR0033 "Blocks not registered"
		#define STR0034 "There are no Blocks that match the degree requested for the eye "
		#define STR0035 "Blocks do not match Dioptry"
		#define STR0036 "Lens ready for the eye "
		#define STR0037 "Blocks (Base) for the eye "
		#define STR0038 "Selection of "
		#define STR0039 "Product Entered : "
		#define STR0040 "Stock Query: "
		#define STR0041 "RIGHT EYE"
		#define STR0042 "LEFT EYE"
		#define STR0043 "Dioptry: ESF "
		#define STR0044 " ; CIL "
		#define STR0045 "Addition"
		#define STR0046 "Code                   Description                                           Reference                      Location   Current Reserv.  Avail.  "
		#define STR0047 "Optometry data"
		#define STR0048 "Optometry - Basis"
		#define STR0049 "Optometry observations:"
	#else
		#define STR0001 "Optometria"
		#define STR0002 If( cPaisLoc $ "ANG|PTG", "Nome do cliente:", "Nome do Cliente:" )
		#define STR0003 "Optometria"
		#define STR0004 If( cPaisLoc $ "ANG|PTG", "Nome do m�dico:", "Nome do M�dico:" )
		#define STR0005 "Paciente: "
		#define STR0006 If( cPaisLoc $ "ANG|PTG", "Artigo", "Produto" )
		#define STR0007 "Optometria - Longe"
		#define STR0008 "Esf�rico"
		#define STR0009 "Cilindro"
		#define STR0010 "Eixo"
		#define STR0011 "DNP"
		#define STR0012 "Altura"
		#define STR0013 "Pel�cula"
		#define STR0014 "DP"
		#define STR0015 "OD"
		#define STR0016 "Optometria - Perto"
		#define STR0017 "OE"
		#define STR0018 "Adi��o"
		#define STR0019 If( cPaisLoc $ "ANG|PTG", "Sr.Cor.", "Srv Cor" )
		#define STR0020 "Optometria "
		#define STR0021 If( cPaisLoc $ "ANG|PTG", " realizada com successo!", " gravada com sucesso!" )
		#define STR0022 If( cPaisLoc $ "ANG|PTG", "Seleccione uma lente gen�rica!", "Selecione uma lente generica!" )
		#define STR0023 If( cPaisLoc $ "ANG|PTG", "Artigo n�o encontrado.", "Produto nao encontrado!" )
		#define STR0024 If( cPaisLoc $ "ANG|PTG", "CRM n�o registrado!", "CRM n�o cadastrado !" )
		#define STR0025 If( cPaisLoc $ "ANG|PTG", "Nao h� lentes prontas associadas ao c�digo ", "Nao ha lentes prontas associadas ao codigo " )
		#define STR0026 " para o olho "
		#define STR0027 "DIREITO"
		#define STR0028 "ESQUERDO"
		#define STR0029 If( cPaisLoc $ "ANG|PTG", ". Blocos ser�o analisados!", ". Blocos serao analisados !" )
		#define STR0030 If( cPaisLoc $ "ANG|PTG", "Lentes prontas n�o registradas.", "Lentes Prontas nao cadastradas" )
		#define STR0031 If( cPaisLoc $ "ANG|PTG", "N�o h� blocos de lentes associados ao c�digo ", "Nao ha blocos de Lentes associados ao codigo " )
		#define STR0032 If( cPaisLoc $ "ANG|PTG", ". N�o � poss�vel prosseguir!", ". Nao e possivel continuar !" )
		#define STR0033 If( cPaisLoc $ "ANG|PTG", "Blocos n�o registrados.", "Blocos nao cadastrados" )
		#define STR0034 If( cPaisLoc $ "ANG|PTG", "N�o h� blocos que atendam ao grau solicitado para o olho ", "Nao ha Blocos que atendam o Grau solicitado para o olho " )
		#define STR0035 If( cPaisLoc $ "ANG|PTG", "Blocos n�o atendem dioptria.", "Blocos nao atendem Dioptria" )
		#define STR0036 If( cPaisLoc $ "ANG|PTG", "Lentes prontas para o olho ", "Lentes Prontas para o olho " )
		#define STR0037 If( cPaisLoc $ "ANG|PTG", "Blocos (bases) para o olho ", "Blocos (Bases) para o olho " )
		#define STR0038 If( cPaisLoc $ "ANG|PTG", "Selec��o de ", "Selecao de " )
		#define STR0039 If( cPaisLoc $ "ANG|PTG", "Artigo digitado: ", "Produto Digitado : " )
		#define STR0040 If( cPaisLoc $ "ANG|PTG", "Consulta stock: ", "Consulta Estoque : " )
		#define STR0041 "OLHO DIREITO"
		#define STR0042 "OLHO ESQUERDO"
		#define STR0043 "Dioptria: ESF "
		#define STR0044 " ; CIL "
		#define STR0045 "Adi��o"
		#define STR0046 If( cPaisLoc $ "ANG|PTG", "C�digo                 Descri��o                                             Refer�ncia                      Local     Actual  Reserv.   Disp.  ", "Codigo                 Descricao                                             Referencia                      Local     Atual  Reserv.   Disp.  " )
		#define STR0047 "Dados da optometria"
		#define STR0048 "Optometria - Base"
		#define STR0049 "Observa��es da optometria:"
	#endif
#endif