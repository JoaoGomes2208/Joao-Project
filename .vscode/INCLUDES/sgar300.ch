#ifdef SPANISH
	#define STR0001 "Informe IBAMA de Residuos Solidos"
	#define STR0002 "SGAR300"
	#define STR0003 "�Totalizar por ?"
	#define STR0004 "Tratamiento"
	#define STR0005 "Receptor"
	#define STR0006 "Ambos"
	#define STR0007 "A rayas"
	#define STR0008 "Administracion"
	#define STR0009 "Informe IBAMA - Residuos Solidos"
	#define STR0010 "Procesando Registros..."
	#define STR0011 "Ano   Tipo Residuo                                           "
	#define STR0012 "   Residuo                                  Clasificacion              Identificacion         Efic. Trat.       Tipo de Monitoreo"
	#define STR0013 "Espere"
	#define STR0014 "Procesando Registros"
	#define STR0015 "Tp. Finalidad:       Finalidad:                              Cantidad Un.  Receptor:                                 RFC:               Lat. Grados:  Min.    Seg.   Tipo: Lon. Grados:  Min.    Seg.   Tipo:"
	#define STR0016 "Contaminantes:"
	#define STR0017 "                Codigo Contaminador  Descripcion                                           Cantidad Un.  Metodo        Identificacion  Sigilo  Justificativa"
	#define STR0018 "No ha contaminantes generados por este residuo en el periodo."
	#define STR0019 "Total:"
	#define STR0020 "No existen datos para elaborar el informe."
#else
	#ifdef ENGLISH
		#define STR0001 "IBAMA Report of Solid Residues"
		#define STR0002 "SGAR300"
		#define STR0003 "Total per ?"
		#define STR0004 "Treatment"
		#define STR0005 "Receiver"
		#define STR0006 "Both"
		#define STR0007 "Z-form"
		#define STR0008 "Management"
		#define STR0009 "IBAMA Report - Solid Residues"
		#define STR0010 "Processing records..."
		#define STR0011 "Year   Residue Type                                           "
		#define STR0012 "   Residue                                   Classification              Identification        Effic. Treat.       Monitoring Type"
		#define STR0013 "Wait"
		#define STR0014 "Processing records"
		#define STR0015 "Tp. Purpose:       Purpose:                              Un. Amount  Receiver:                                 CNPJ:               Lat. Degrees:  Min.    Sec.   Type: Lon. Degrees:  Min.    Mon   Type:"
		#define STR0016 "Pollutants:"
		#define STR0017 "                Pollutant Code   Description                                         Quantity   Un.  Method        Identification Secrecy Reason"
		#define STR0018 "There are no pollutants generated by this residue on the period."
		#define STR0019 "Total:"
		#define STR0020 "There are no data to generate the report."
	#else
		#define STR0001 "Relat�rio IBAMA de Res�duos S�lidos"
		#define STR0002 "SGAR300"
		#define STR0003 If( cPaisLoc $ "ANG|PTG", "Totalizar por?", "Totalizar por ?" )
		#define STR0004 "Tratamento"
		#define STR0005 "Receptor"
		#define STR0006 "Ambos"
		#define STR0007 If( cPaisLoc $ "ANG|PTG", "C�digo de barras", "Zebrado" )
		#define STR0008 If( cPaisLoc $ "ANG|PTG", "Administra��o", "Administracao" )
		#define STR0009 "Relat�rio IBAMA - Res�duos S�lidos"
		#define STR0010 If( cPaisLoc $ "ANG|PTG", "A processar registos...", "Processando Registros..." )
		#define STR0011 "Ano   Tipo Res�duo                                           "
		#define STR0012 "   Res�duo                                   Classifica��o              Identifica��o         Efic. Trat.       Tipo de Monitoramento"
		#define STR0013 "Aguarde"
		#define STR0014 If( cPaisLoc $ "ANG|PTG", "A processar registos", "Processando Registros" )
		#define STR0015 "Tp. Finalidade:       Finalidade:                              Quantidade Un.  Receptor:                                 CNPJ:               Lat. Graus:  Min.    Seg.   Tipo: Lon. Graus:  Min.    Seg.   Tipo:"
		#define STR0016 "Poluentes:"
		#define STR0017 "                C�digo Poluente  Descri��o                                           Quantidade Un.  M�todo        Identifica��o  Sigilo  Justificativa"
		#define STR0018 "N�o existem poluentes gerados por este res�duo no per�odo."
		#define STR0019 "Total :"
		#define STR0020 "N�o existem dados para montar o relat�rio."
	#endif
#endif