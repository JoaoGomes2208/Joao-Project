#ifdef SPANISH
	#define STR0001 "Buscar"
	#define STR0002 "Visualizar"
	#define STR0003 "Incluir"
	#define STR0004 "Modificar"
	#define STR0005 "Borrar"
	#define STR0006 "Imprimir"
	#define STR0007 "Tipo de Garantia"
	#define STR0008 "Modelo de Datos de Tipo de Garantia"
	#define STR0009 "Datos de Tipo de Garantia"
	#define STR0010 "No se permite tener grupo de aprobacion para Autorizacion"
	#define STR0011 "Config. Inicial"
	#define STR0012 "Se incluir�n nuevos tipos de garant�a est�ndar. �Desea continuar?"
	#define STR0013 "Error en la carga de configuraci�n inicial #1 "
	#define STR0014 "Final de la configuraci�n"
	#define STR0015 "Inventario de bienes"
	#define STR0016 "Carta de fianza"
	#define STR0017 "Garant�a"
	#define STR0018 "Dep�sito judicial"
	#define STR0019 "An�lisis"
	#define STR0020 "En garant�a"
#else
	#ifdef ENGLISH
		#define STR0001 "Search"
		#define STR0002 "View"
		#define STR0003 "Add"
		#define STR0004 "Edit"
		#define STR0005 "Delete"
		#define STR0006 "Print"
		#define STR0007 "Type of Guarantee"
		#define STR0008 "Data Model of Guarantee Type"
		#define STR0009 "Data of Guarantee Type"
		#define STR0010 "You cannot have an approval group for Permit"
		#define STR0011 "Initial Config."
		#define STR0012 "New Types of Standard Warranty Continue?"
		#define STR0013 "Error loading initial configuration #1 "
		#define STR0014 "End of Configuration"
		#define STR0015 "Assets Enrollment"
		#define STR0016 "Letter of Guarantee"
		#define STR0017 "Bond"
		#define STR0018 "Legal Deposit"
		#define STR0019 "Survey"
		#define STR0020 "Pledge"
	#else
		#define STR0001 "Pesquisar"
		#define STR0002 "Visualizar"
		#define STR0003 "Incluir"
		#define STR0004 "Alterar"
		#define STR0005 If( cPaisLoc $ "ANG|PTG", "Eliminar", "Excluir" )
		#define STR0006 "Imprimir"
		#define STR0007 "Tipo de Garantia"
		#define STR0008 If( cPaisLoc $ "ANG|PTG", "Modelo de dados de tipo de garantia", "Modelo de Dados de Tipo de Garantia" )
		#define STR0009 If( cPaisLoc $ "ANG|PTG", "Dados de tipo de garantia", "Dados de Tipo de Garantia" )
		#define STR0010 "N�o � permitido ter grupo de aprova��o para Alvar�"
		#define STR0011 "Config. Inicial"
		#define STR0012 "Ser�o inclu�dos novos Tipos de Garantia padr�o. Deseja continuar?"
		#define STR0013 "Erro na carga da configura��o inicial #1 "
		#define STR0014 "Final da Configura��o"
		#define STR0015 "Arrolamento de Bens"
		#define STR0016 "Carta de Fian�a"
		#define STR0017 "Cau��o"
		#define STR0018 "Dep�sito Judicial"
		#define STR0019 "Levantamento"
		#define STR0020 "Penhora"
	#endif
#endif