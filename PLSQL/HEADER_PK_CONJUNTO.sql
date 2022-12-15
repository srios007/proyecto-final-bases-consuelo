CREATE OR REPLACE PACKAGE PK_CONJUNTOS AS
 /*-----------------------------------------------------------------------------------
Proyecto : Propiedad horizontal Conjuntos. Curso BDII
Descripcion: Paquete que contiene las variables globales, funciones y procedimientos
asociados al módulo de Conjuntos
Autores:     
    Christian Caro Vargas (20181020027)

    Edwin Hernández Cabrera (20152020013)

    José Luis Quintero Cañizalez (20181020061)

    Juan Sebastián González Forero (20181020029)

    Santiago Ríos Valero (20181020017) 
------------------------------------------------------------------------------------*/
 --Declaración del tipo registro con los datos de un apartamento con saldos en mora
    TYPE GTR_APTOS_MORA IS
        RECORD( NOMBRE_CONJUNTO CONJUNTO.NOMBRE_CONJUNTO%TYPE, COD_BLOQUE APARTAMENTO.COD_BLOQUE%TYPE, COD_APARTAMENTO APARTAMENTO.COD_APARTAMENTO%TYPE, SALDO_PENDIENTE CUENTA_COBRO.SALDO_PENDIENTE%TYPE, FECHA_PAGO PAGO.FECHA_PAGO%TYPE );
 --Declaración del tipo registro con los datos básicos
    TYPE GTR_PERSONA_APTO IS
        RECORD( COD_APARTAMENTO APARTAMENTO.COD_APARTAMENTO%TYPE, NOMBRE_CONJUNTO CONJUNTO.NOMBRE_CONJUNTO%TYPE, COD_BLOQUE APARTAMENTO.COD_BLOQUE%TYPE, NOMBRE1_PERSONA PERSONA.NOMBRE1_PERSONA%TYPE, APELLIDO1_PERSONA PERSONA.APELLIDO1_PERSONA%TYPE );
 --Declaración del tipo registro con los datos básicos
    TYPE GTR_CUENTA_APTO IS
        RECORD( NOMBRE_CONJUNTO CONJUNTO.NOMBRE_CONJUNTO%TYPE, COD_APARTAMENTO APARTAMENTO.COD_APARTAMENTO%TYPE, COD_BLOQUE APARTAMENTO.COD_BLOQUE%TYPE, AREA_APARTAMENTO APARTAMENTO.AREA_APARTAMENTO%TYPE, COEF_ADMINISTRACION APARTAMENTO.COEF_ADMINISTRACION%TYPE, NOMBRE1_PERSONA PERSONA.NOMBRE1_PERSONA%TYPE, APELLIDO1_PERSONA PERSONA.APELLIDO1_PERSONA%TYPE, PERIODO_MES_CUENTA CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE, PERIODO_ANIO_CUENTA CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE, SALDO_PENDIENTE CUENTA_COBRO.SALDO_PENDIENTE%TYPE, VALOR_MORA CUENTA_COBRO.VALOR_MORA%TYPE, VALOR_DESCUENTO CUENTA_COBRO.VALOR_DESCUENTO%TYPE, SALDO_ACTUAL CUENTA_COBRO.SALDO_ACTUAL%TYPE );
 -- Variable global de tipo registro aptos en mora
    GR_APTOS_MORA GTR_APTOS_MORA;
 /*-----------------------------------------------------------------------------------
Procedimiento que retorna el valor a pagar de un apartamento dado
Parámetros de Entrada:  PK_APTO         Código del apartamento
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_CONJUNTO     Código del conjunto de apartamentos
                        PF_MES          Periodo del mes 
                        PF_ANIO         Periodo del año

Parámetros de Salida:   PV_ACTUAL       Valor del saldo actual
                        PV_PENDIENTE    valor del saldo pendiente
                        PV_INTERES      valor del interes 
                        PV_DESCUENTO    valor del descuento 
------------------------------------------------------------------------------------*/
    PROCEDURE PR_CALC_PAGO (
        PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
        PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
        PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
        PF_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
        PF_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE,
        PV_ACTUAL OUT CUENTA_COBRO.SALDO_ACTUAL%TYPE,
        PV_PENDIENTE OUT CUENTA_COBRO.SALDO_PENDIENTE%TYPE,
        PV_INTERES OUT CUENTA_COBRO.VALOR_MORA%TYPE,
        PV_DESCUENTO OUT CUENTA_COBRO.VALOR_DESCUENTO%TYPE,
        PC_ERROR OUT INTEGER,
        PM_ERROR OUT VARCHAR
    );
 /*-----------------------------------------------------------------------------------
Procedimiento para pagar una cuenta de cobro
Parámetros de Entrada:  PK_APTO         Código del apartamento
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_CONJUNTO     Código del conjunto de apartamentos
                        PV_PAGO         Valor del pago  
                        PT_PAGO         Forma o tipo de pago

Parámetros de Salida:   PC_ERROR         1 si no existe, 0 , en caso contrario
                        PM_ERROR        Mensaje de error si hay error o null en caso contrario

------------------------------------------------------------------------------------*/
    PROCEDURE PR_PAGAR_CUENTA (
        PK_APTO IN PAGO.COD_APARTAMENTO%TYPE,
        PK_BLOQUE IN PAGO.COD_BLOQUE%TYPE,
        PK_CONJUNTO IN PAGO.COD_CONJUNTO%TYPE,
        PV_PAGO IN PAGO.VALOR_PAGADO%TYPE,
        PT_PAGO IN PAGO.FORMA_PAGO%TYPE,
        PC_ERROR OUT INTEGER,
        PM_ERROR OUT VARCHAR
    );
 /*-----------------------------------------------------------------------------------
Procedimiento para reservar una zona común
Parámetros de Entrada:  PID_PERSONA         Código de identificación de la persona
                        PK_ZONA_CONJUNTO    Código de la zona del conjunto
                        PN_CONJUNTO         Nombre del conjunto de apartamentos
                        PF_INICIAL          Fecha incial  
                        PF_FINAL            Fecha final

Parámetros de Salida:   PC_ERROR            1 si no existe, 0 , en caso contrario
                        PM_ERROR            Mensaje de error si hay error o null en caso contrario

------------------------------------------------------------------------------------*/
    PROCEDURE PR_CREAR_RESERVA (
        PID_PERSONA IN PERSONA.IDENTIFICACION_PERSONA%TYPE,
        PK_ZONA_CONJUNTO IN ZONA_CONJUNTO.COD_ZONA_CONJUNTO%TYPE,
        PN_CONJUNTO IN CONJUNTO.NOMBRE_CONJUNTO%TYPE,
        PF_INICIAL IN RESERVA.FECHA_INICIAL%TYPE,
        PF_FINAL IN RESERVA.FECHA_FINAL%TYPE,
        PC_ERROR OUT INTEGER,
        PM_ERROR OUT VARCHAR
    );
 /*-----------------------------------------------------------------------------------
Procedimiento para crear la cuenta de cobro de un apartamento dado
Parámetros de Entrada:  PK_APTO         Código del apartamento
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_CONJUNTO     Código del conjunto de apartamentos
                        PN_MES          Valor del mes de la cuenta de cobro 
                        PN_ANIO         Valor del año de la cuenta de cobro

Parámetros de Salida:   PC_ERROR         1 si no existe, 0 , en caso contrario
                        PM_ERROR        Mensaje de error si hay error o null en caso contrario

------------------------------------------------------------------------------------*/
    PROCEDURE PR_CREAR_CUENTA_COBRO (
        PK_APTO IN CUENTA_COBRO.COD_APARTAMENTO%TYPE,
        PK_BLOQUE IN CUENTA_COBRO.COD_BLOQUE%TYPE,
        PK_CONJUNTO IN CUENTA_COBRO.COD_CONJUNTO%TYPE,
        PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
        PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE,
        PC_ERROR OUT INTEGER,
        PM_ERROR OUT VARCHAR
    );
 /*-----------------------------------------------------------------------------------
Procedimiento para pagar la cuenta de cobro (con saldo > 0) más antigua.
Parámetros de Entrada:  PK_CONJUNTO     Código del conjunto de apartamentos
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_APTO         Código del apartamento
                        PV_PAGADO       Valor pagado  
                        PT_PAGO         Forma o tipo de pago

Parámetros de Salida:   PC_ERROR         1 si no existe, 0 , en caso contrario
                        PM_ERROR        Mensaje de error si hay error o null en caso contrario

------------------------------------------------------------------------------------*/
    PROCEDURE PR_PAGAR_SALDO (
        PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
        PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
        PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
        PV_PAGADO IN PAGO.VALOR_PAGADO%TYPE
    );
 /*-----------------------------------------------------------------------------------
Procedimiento para recalcular los saldos pendientes de una cuenta de cobro.
Parámetros de Entrada:  PK_CONJUNTO     Código del conjunto de apartamentos
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_APTO         Código del apartamento
                        PN_MES          Periodo del mes de la cuenta de cobro
                        PN_ANIO         Periodo del año de la cuenta de cobro


Parámetros de Salida:   PC_ERROR         1 si no existe, 0 , en caso contrario
                        PM_ERROR        Mensaje de error si hay error o null en caso contrario
------------------------------------------------------------------------------------*/
    PROCEDURE PR_SALDO_PENDIENTE (
        PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
        PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
        PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
        PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
        PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE
    );
 /*-----------------------------------------------------------------------------------
Procedimiento para establecer en cero el saldo actual y el saldo pendiente de una cuenta de cobro
Parámetros de Entrada:  PK_CONJUNTO     Código del conjunto de apartamentos
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_APTO         Código del apartamento
                        PN_MES          Periodo del mes de la cuenta de cobro
                        PN_ANIO         Periodo del año de la cuenta de cobro


Parámetros de Salida:   PC_ERROR         1 si no existe, 0 , en caso contrario
                        PM_ERROR        Mensaje de error si hay error o null en caso contrario
------------------------------------------------------------------------------------*/
    PROCEDURE PR_INIT_SALDOS (
        PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
        PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
        PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
        PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
        PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE
    );
 /*-----------------------------------------------------------------------------------
Procedimiento que calcula el valor de descuento o mora de las cuentas de cobro del último mes y lo inserta en la cuenta de cobro.
Parámetros de Salida:   PC_ERROR         1 si no existe, 0 , en caso contrario
                        PM_ERROR        Mensaje de error si hay error o null en caso contrario
------------------------------------------------------------------------------------*/
    PROCEDURE PR_CALC_DESC_MORA (
        PC_ERROR OUT INTEGER,
        PM_ERROR OUT VARCHAR
    );
 /*-----------------------------------------------------------------------------------
Función para calcular el saldo actual de una cuenta de cobro
Parámetros de Entrada:  PK_CONJUNTO     Código del conjunto de apartamentos
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_APTO         Código del apartamento
                        PN_MES          Periodo del mes de la cuenta de cobro
                        PN_ANIO         Periodo del año de la cuenta de cobro

------------------------------------------------------------------------------------*/
    FUNCTION FU_CALC_V_ACTUAL (
        PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
        PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
        PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
        PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
        PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE
    ) RETURN CUENTA_COBRO.SALDO_ACTUAL%TYPE;
 /*-----------------------------------------------------------------------------------
Función para calcular el saldo pendiente de una cuenta de cobro
Parámetros de Entrada:  PK_CONJUNTO     Código del conjunto de apartamentos
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_APTO         Código del apartamento
                        PN_MES          Periodo del mes de la cuenta de cobro
                        PN_ANIO         Periodo del año de la cuenta de cobro

------------------------------------------------------------------------------------*/
    FUNCTION FU_CALC_V_PENDIENTE (
        PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
        PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
        PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
        PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
        PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE
    ) RETURN CUENTA_COBRO.SALDO_PENDIENTE%TYPE;
 /*-----------------------------------------------------------------------------------
Función que devuelve un listado de los apartamentos con saldos pendientes
No se que poner aca

------------------------------------------------------------------------------------*/
    FUNCTION FU_APTOS_EN_MORA RETURN GTR_APTOS_MORA;
 /*-----------------------------------------------------------------------------------
Función que devuelve un listado de las personas asociadas a su apartamento.
Parámetros de Entrada:  PK_APTO         Código del apartamento
                        PK_BLOQUE       Código del bloque de apartamentos
                        PK_CONJUNTO     Código del conjunto de apartamentos


------------------------------------------------------------------------------------*/
    FUNCTION FU_MOSTRAR_PERSONAS(
        PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
        PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
        PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE
    ) RETURN GTR_PERSONA_APTO;
 /*-----------------------------------------------------------------------------------
Función que devuelve la cuenta de cobro de un apartamento para un mes dado.
Parámetros de Entrada:  PK_CONJUNTO     Código del conjunto de apartamentos
                        PK_APTO         Código del apartamento
                        PK_BLOQUE       Código del bloque de apartamentos
                        PID_PERSONA     Código de identificación de una persona
                        PN_MES          Periodo del mes de la cuenta de cobro
                        PN_ANIO         Periodo del año de la cuenta de cobro


------------------------------------------------------------------------------------*/
    FUNCTION FU_MOSTRAR_CUENTA(
        PN_CONJUNTO IN CONJUNTO.NOMBRE_CONJUNTO%TYPE,
        PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
        PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
        PID_PERSONA IN PERSONA.IDENTIFICACION_PERSONA%TYPE,
        PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
        PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE
    ) RETURN GTR_CUENTA_APTO;
END PK_CONJUNTOS;
/