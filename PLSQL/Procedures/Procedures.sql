------------------------------------------------------ Procedimiento que retorna el valor a pagar de un apartamento dado
CREATE OR REPLACE PROCEDURE PR_CALC_PAGO (
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
) AS
BEGIN
    SELECT
        DISTINCT SALDO_ACTUAL,
        SALDO_PENDIENTE,
        VALOR_MORA,
        VALOR_DESCUENTO INTO PV_ACTUAL,
        PV_PENDIENTE,
        PV_INTERES,
        PV_DESCUENTO
    FROM
        CONJUNTO     C,
        APARTAMENTO  A,
        CUENTA_COBRO CC
    WHERE
        CC.COD_APARTAMENTO = A.COD_APARTAMENTO
        AND CC.COD_BLOQUE = A.COD_BLOQUE
        AND CC.COD_CONJUNTO = A.COD_CONJUNTO
        AND A.COD_CONJUNTO = C.COD_CONJUNTO
        AND C.COD_CONJUNTO = PK_CONJUNTO
        AND A.COD_APARTAMENTO = PK_APTO
        AND A.COD_BLOQUE = PK_BLOQUE
        AND CC.PERIODO_MES_CUENTA = PF_MES
        AND CC.PERIODO_ANIO_CUENTA = PF_ANIO;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        PC_ERROR := 1;
        PM_ERROR := 'PR_CALC_PAGO No data found';
    WHEN TOO_MANY_ROWS THEN
        PC_ERROR := 1;
        PM_ERROR := 'PR_CALC_PAGO Too many rows';
    WHEN OTHERS THEN
        PC_ERROR := 1;
        PM_ERROR := 'PR_CALC_PAGO "OTHERS" raised';
        RAISE_APPLICATION_ERROR(-20001, 'PR_CALC_PAGO Ha ocurrido un error: '
            || SQLCODE
            || SQLERRM);
END PR_CALC_PAGO;
/

------------------------------------------------------ Bloque anónimo para llamar al procedimiento PR_CALC_PAGO
DECLARE
    LK_APTO      APARTAMENTO.COD_APARTAMENTO%TYPE := '402';
    LK_BLOQUE    APARTAMENTO.COD_BLOQUE%TYPE := '11';
    LK_CONJUNTO  CONJUNTO.COD_CONJUNTO%TYPE := 1;
    LF_MES       CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE := 12;
    LF_ANIO      CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE := 2022;
    LV_PENDIENTE CUENTA_COBRO.SALDO_PENDIENTE%TYPE;
    LV_ACTUAL    CUENTA_COBRO.SALDO_ACTUAL%TYPE;
    LV_INTERES   CUENTA_COBRO.VALOR_MORA%TYPE;
    LV_DESCUENTO CUENTA_COBRO.VALOR_DESCUENTO%TYPE;
    LC_ERROR     INTEGER;
    LM_ERROR     VARCHAR(100);
BEGIN
    PR_CALC_PAGO(LK_APTO, LK_BLOQUE, LK_CONJUNTO, LF_MES, LF_ANIO, LV_ACTUAL, LV_PENDIENTE, LV_INTERES, LV_DESCUENTO, LC_ERROR, LM_ERROR);
    DBMS_OUTPUT.PUT_LINE(LV_PENDIENTE);
    DBMS_OUTPUT.PUT_LINE(LV_ACTUAL);
    DBMS_OUTPUT.PUT_LINE(LV_DESCUENTO);
    DBMS_OUTPUT.PUT_LINE(LV_INTERES);
END;
/

------------------------------------------------------ Procedimiento para pagar una cuenta de cobro
CREATE OR REPLACE PROCEDURE PR_PAGAR_CUENTA (
    PK_APTO IN PAGO.COD_APARTAMENTO%TYPE,
    PK_BLOQUE IN PAGO.COD_BLOQUE%TYPE,
    PK_CONJUNTO IN PAGO.COD_CONJUNTO%TYPE,
    PV_PAGO IN PAGO.VALOR_PAGADO%TYPE,
    PT_PAGO IN PAGO.FORMA_PAGO%TYPE,
    PC_ERROR OUT INTEGER,
    PM_ERROR OUT VARCHAR
) AS
    LK_PAGO   PAGO.COD_PAGO%TYPE;
    LK_CUENTA PAGO.COD_CUENTA_COBRO%TYPE;
BEGIN
    SELECT
        MAX(COD_CUENTA_COBRO) INTO LK_CUENTA
    FROM
        CUENTA_COBRO
    WHERE
        COD_CONJUNTO = PK_CONJUNTO
        AND COD_BLOQUE = PK_BLOQUE
        AND COD_APARTAMENTO = PK_APTO
    GROUP BY
        SALDO_PENDIENTE
    HAVING
        SALDO_PENDIENTE = 0;
    IF LK_CUENTA IS NULL THEN
        LK_CUENTA := 1;
        LK_PAGO := 1;
    ELSE
        SELECT
            MAX(COD_PAGO) INTO LK_PAGO
        FROM
            PAGO
        WHERE
            COD_CUENTA_COBRO = LK_CUENTA;
        IF LK_PAGO IS NULL THEN
            LK_PAGO := 1;
        ELSE
            LK_PAGO := LK_PAGO + 1;
        END IF;
    END IF;
    INSERT INTO PAGO (
        COD_PAGO,
        COD_CUENTA_COBRO,
        COD_APARTAMENTO,
        COD_BLOQUE,
        COD_CONJUNTO,
        VALOR_PAGADO,
        FECHA_PAGO,
        FORMA_PAGO
    ) VALUES (
        LK_PAGO,
        LK_CUENTA,
        PK_APTO,
        PK_BLOQUE,
        PK_CONJUNTO,
        PV_PAGO,
        (SELECT CURRENT_TIMESTAMP FROM DUAL),
        PT_PAGO
    );
    PR_CALC_DESC_MORA(PC_ERROR, PM_ERROR);
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        PC_ERROR := 1;
        PM_ERROR := 'Error al pagar la cuenta de cobro '
            || LK_CUENTA;
        RAISE_APPLICATION_ERROR(-20001, 'PR_PAGAR_CUENTA Ha ocurrido un error: '
            || SQLCODE
            || SQLERRM);
END PR_PAGAR_CUENTA;
/

------------------------------------------------------ Bloque anónimo para llamar al procedimiento PR_PAGAR_CUENTA
DECLARE
    K_APTO     PAGO.COD_APARTAMENTO%TYPE := 402;
    K_BLOQUE   PAGO.COD_BLOQUE%TYPE := 11;
    K_CONJUNTO PAGO.COD_CONJUNTO%TYPE := 1;
    V_PAGO     PAGO.VALOR_PAGADO%TYPE := 100000;
    T_PAGO     PAGO.FORMA_PAGO%TYPE := 'Débito';
    C_ERROR    INTEGER;
    M_ERROR    VARCHAR(150);
BEGIN
    PR_PAGAR_CUENTA(K_APTO, K_BLOQUE, K_CONJUNTO, V_PAGO, T_PAGO, C_ERROR, M_ERROR);
END;
/

------------------------------------------------------ Procedimiento para reservar una zona común
CREATE OR REPLACE PROCEDURE PR_CREAR_RESERVA (
    PID_PERSONA IN PERSONA.IDENTIFICACION_PERSONA%TYPE,
    PK_ZONA_CONJUNTO IN ZONA_CONJUNTO.COD_ZONA_CONJUNTO%TYPE,
    PN_CONJUNTO IN CONJUNTO.NOMBRE_CONJUNTO%TYPE,
    PF_INICIAL IN RESERVA.FECHA_INICIAL%TYPE,
    PF_FINAL IN RESERVA.FECHA_FINAL%TYPE,
    PC_ERROR OUT INTEGER,
    PM_ERROR OUT VARCHAR
)AS
    LK_CONJUNTO CONJUNTO.COD_CONJUNTO%TYPE;
    LK_PERSONA  PERSONA.COD_PERSONA%TYPE;
    LF_ACTUAL   RESERVA.FECHA_RESERVA%TYPE;
    LN_HORAS    RESERVA.NUM_HORAS_RESERVADAS%TYPE;
    LK_RESERVA  RESERVA.COD_RESERVA%TYPE;
BEGIN
    SELECT
        MAX(COD_RESERVA) INTO LK_RESERVA
    FROM
        RESERVA;
    IF LK_RESERVA IS NULL THEN
        LK_RESERVA := 1;
    ELSE
        LK_RESERVA := LK_RESERVA + 1;
    END IF;
    DBMS_OUTPUT.PUT_LINE(LK_RESERVA);
    SELECT
        COD_CONJUNTO INTO LK_CONJUNTO
    FROM
        CONJUNTO
    WHERE
        NOMBRE_CONJUNTO = PN_CONJUNTO;
    DBMS_OUTPUT.PUT_LINE(LK_CONJUNTO);
    SELECT
        COD_PERSONA INTO LK_PERSONA
    FROM
        PERSONA
    WHERE
        IDENTIFICACION_PERSONA = PID_PERSONA;
    DBMS_OUTPUT.PUT_LINE(LK_PERSONA);
    SELECT
        CURRENT_TIMESTAMP INTO LF_ACTUAL
    FROM
        DUAL;
    LN_HORAS := EXTRACT(HOUR FROM (PF_FINAL - PF_INICIAL));
    INSERT INTO RESERVA (
        COD_RESERVA,
        COD_PERSONA,
        COD_ZONA_CONJUNTO,
        COD_CONJUNTO,
        FECHA_RESERVA,
        NUM_HORAS_RESERVADAS,
        FECHA_INICIAL,
        FECHA_FINAL,
        ES_RESERVA_ACTIVA,
        COSTO_TOTAL_RESERVA
    ) VALUES (
        LK_RESERVA,
        LK_PERSONA,
        PK_ZONA_CONJUNTO,
        LK_CONJUNTO,
        LF_ACTUAL,
        LN_HORAS,
        PF_INICIAL,
        PF_FINAL,
        'S',
        0
    );
    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        PC_ERROR := 1;
        PM_ERROR := 'No hay filas retornadas por una consulta al crear la reserva.';
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'PR_CREAR_RESERVA Sin filas retornadas ');
    WHEN TOO_MANY_ROWS THEN
        PC_ERROR := 1;
        PM_ERROR := 'Demasiadas filas retornadas por una consulta al crear la reserva.';
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20002, 'PR_CREAR_RESERVA Demasiadas filas retornadas ');
    WHEN OTHERS THEN
        PC_ERROR := 1;
        PM_ERROR := 'Error al crear la reserva '
            || LK_RESERVA;
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20001, 'PR_CREAR_RESERVA Ha ocurrido un error: '
            || SQLCODE
            || SQLERRM);
END PR_CREAR_RESERVA;
/

------------------------------------------------------ Bloque anónimo para llamar al procedimiento PR_CREAR_RESERVA
DECLARE
    ID_PERSONA      PERSONA.IDENTIFICACION_PERSONA%TYPE := 1010010101;
    K_ZONA_CONJUNTO ZONA_CONJUNTO.COD_ZONA_CONJUNTO%TYPE := 2;
    N_CONJUNTO      CONJUNTO.NOMBRE_CONJUNTO%TYPE := 'Torres de Cantabria';
    F_INICIAL       RESERVA.FECHA_INICIAL%TYPE := TO_DATE('26/12/2022 15:00', 'DD/MM/YYYY HH24:MI');
    F_FINAL         RESERVA.FECHA_FINAL%TYPE := TO_DATE('26/12/2022 20:00', 'DD/MM/YYYY HH24:MI');
    C_ERROR         INTEGER;
    M_ERROR         VARCHAR(150);
BEGIN
    PR_CREAR_RESERVA(ID_PERSONA, K_ZONA_CONJUNTO, N_CONJUNTO, F_INICIAL, F_FINAL, C_ERROR, M_ERROR);
END;
/

------------------------------------------------------ Procedimiento para crear la cuenta de cobro de un apartamento dado
CREATE OR REPLACE PROCEDURE PR_CREAR_CUENTA_COBRO (
    PK_APTO IN CUENTA_COBRO.COD_APARTAMENTO%TYPE,
    PK_BLOQUE IN CUENTA_COBRO.COD_BLOQUE%TYPE,
    PK_CONJUNTO IN CUENTA_COBRO.COD_CONJUNTO%TYPE,
    PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
    PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE,
    PC_ERROR OUT INTEGER,
    PM_ERROR OUT VARCHAR
)AS
    LK_CUENTA CUENTA_COBRO.COD_CUENTA_COBRO%TYPE;
BEGIN
    SELECT
        MAX(COD_CUENTA_COBRO) INTO LK_CUENTA
    FROM
        CUENTA_COBRO;
    IF LK_CUENTA IS NULL THEN
        LK_CUENTA := 1;
    ELSE
        LK_CUENTA := LK_CUENTA + 1;
    END IF;
    INSERT INTO CUENTA_COBRO (
        COD_CUENTA_COBRO,
        COD_APARTAMENTO,
        COD_BLOQUE,
        COD_CONJUNTO,
        PERIODO_MES_CUENTA,
        PERIODO_ANIO_CUENTA,
        VALOR_DESCUENTO,
        VALOR_MORA,
        SALDO_PENDIENTE,
        SALDO_ACTUAL,
        FECHA_CUENTA,
        ESTADO_CUENTA
    ) VALUES (
        LK_CUENTA,
        PK_APTO,
        PK_BLOQUE,
        PK_CONJUNTO,
        PN_MES,
        PN_ANIO,
        0,
        0,
        0,
        0,
        (SELECT CURRENT_DATE FROM DUAL),
        'Pendiente'
    );
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        PC_ERROR := 1;
        PM_ERROR := 'Ha ocurrido un error al crear la cuenta de cobro número: '
            || LK_CUENTA;
        RAISE_APPLICATION_ERROR(-20001, 'PR_CREAR_CUENTA_COBRO Ha ocurrido un error: '
            || SQLCODE
            || SQLERRM);
END PR_CREAR_CUENTA_COBRO;
/

------------------------------------------------------ Bloque anónimo para llamar al procedimiento PR_CREAR_CUENTA_COBRO
DECLARE
    K_APTO     CUENTA_COBRO.COD_APARTAMENTO%TYPE := 402;
    K_BLOQUE   CUENTA_COBRO.COD_BLOQUE%TYPE := 11;
    K_CONJUNTO CUENTA_COBRO.COD_CONJUNTO%TYPE := 1;
    N_MES      CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE := 9;
    N_ANIO     CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE := 2022;
    C_ERROR    INTEGER;
    M_ERROR    VARCHAR(150);
BEGIN
    PR_CREAR_CUENTA_COBRO(K_APTO, K_BLOQUE, K_CONJUNTO, N_MES, N_ANIO, C_ERROR, M_ERROR);
END;
/

------------------------------------------------------ Procedimiento para pagar la cuenta de cobro (con saldo > 0) más antigua.
CREATE OR REPLACE PROCEDURE PR_PAGAR_SALDO (
    PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
    PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
    PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
    PV_PAGADO IN PAGO.VALOR_PAGADO%TYPE
) AS
    LS_ACTUAL    CUENTA_COBRO.SALDO_ACTUAL%TYPE;
    LS_PENDIENTE CUENTA_COBRO.SALDO_PENDIENTE%TYPE;
    LS_RESTANTE  CUENTA_COBRO.SALDO_ACTUAL%TYPE;
    LN_MES       CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE;
    LN_ANIO      CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE;
    LF_ACTUAL    PAGO.FECHA_PAGO%TYPE;
    L_NUM        INTEGER;
BEGIN
    SELECT
        MAX(PERIODO_MES_CUENTA),
        MAX(PERIODO_ANIO_CUENTA) INTO LN_MES,
        LN_ANIO
    FROM
        CUENTA_COBRO
    WHERE
        COD_CONJUNTO = PK_CONJUNTO
        AND COD_BLOQUE = PK_BLOQUE
        AND COD_APARTAMENTO = PK_APTO
    GROUP BY
        PERIODO_ANIO_CUENTA
    ORDER BY
        PERIODO_ANIO_CUENTA DESC FETCH FIRST 1 ROWS ONLY;
    SELECT
        FU_CALC_V_PENDIENTE(PK_CONJUNTO,
        PK_BLOQUE,
        PK_APTO,
        LN_MES,
        LN_ANIO) INTO LS_PENDIENTE
    FROM
        DUAL;
    SELECT
        FU_CALC_V_ACTUAL(PK_CONJUNTO,
        PK_BLOQUE,
        PK_APTO,
        LN_MES,
        LN_ANIO) INTO LS_ACTUAL
    FROM
        DUAL;
    IF LS_PENDIENTE <= 0 THEN
        UPDATE CUENTA_COBRO
        SET
            SALDO_ACTUAL = SALDO_ACTUAL - (
                PV_PAGADO + LS_PENDIENTE
            )
        WHERE
            COD_CONJUNTO = PK_CONJUNTO
            AND COD_BLOQUE = PK_BLOQUE
            AND COD_APARTAMENTO = PK_APTO
            AND PERIODO_MES_CUENTA = LN_MES
            AND PERIODO_ANIO_CUENTA = LN_ANIO;
    ELSIF (LS_ACTUAL + LS_PENDIENTE) <= PV_PAGADO THEN
        UPDATE CUENTA_COBRO
        SET
            SALDO_PENDIENTE = 0,
            SALDO_ACTUAL = (
                LS_ACTUAL + LS_PENDIENTE
            ) - PV_PAGADO,
            ESTADO_CUENTA = 'Pagado'
        WHERE
            COD_CONJUNTO = PK_CONJUNTO
            AND COD_BLOQUE = PK_BLOQUE
            AND COD_APARTAMENTO = PK_APTO
            AND PERIODO_MES_CUENTA = LN_MES
            AND PERIODO_ANIO_CUENTA = LN_ANIO;
        PR_INIT_SALDOS (PK_CONJUNTO, PK_BLOQUE, PK_APTO, LN_MES - 1, LN_ANIO);
    ELSIF LS_PENDIENTE > 0 THEN
        IF LN_MES > 1 THEN
            L_NUM := LN_MES - 1;
        ELSE
            L_NUM := 12;
            LN_ANIO := LN_ANIO - 1;
        END IF;
        LOOP
            SELECT
                FU_CALC_V_PENDIENTE(PK_CONJUNTO,
                PK_BLOQUE,
                PK_APTO,
                L_NUM,
                LN_ANIO) INTO LS_PENDIENTE
            FROM
                DUAL;
            IF LS_PENDIENTE <= 0 THEN
                SELECT
                    FU_CALC_V_ACTUAL(PK_CONJUNTO,
                    PK_BLOQUE,
                    PK_APTO,
                    L_NUM,
                    LN_ANIO) INTO LS_ACTUAL
                FROM
                    DUAL;
                UPDATE CUENTA_COBRO
                SET
                    SALDO_ACTUAL = LS_ACTUAL - (
                        PV_PAGADO + LS_PENDIENTE
                    )
                WHERE
                    COD_CONJUNTO = PK_CONJUNTO
                    AND COD_BLOQUE = PK_BLOQUE
                    AND COD_APARTAMENTO = PK_APTO
                    AND PERIODO_MES_CUENTA = L_NUM
                    AND PERIODO_ANIO_CUENTA = LN_ANIO;
                IF L_NUM = 12 THEN
                    L_NUM := 0;
                    LN_ANIO := LN_ANIO + 1;
                END IF;
                UPDATE CUENTA_COBRO
                SET
                    SALDO_PENDIENTE = LS_ACTUAL - (
                        PV_PAGADO + LS_PENDIENTE
                    )
                WHERE
                    COD_CONJUNTO = PK_CONJUNTO
                    AND COD_BLOQUE = PK_BLOQUE
                    AND COD_APARTAMENTO = PK_APTO
                    AND PERIODO_MES_CUENTA = L_NUM + 1
                    AND PERIODO_ANIO_CUENTA = LN_ANIO;
                PR_SALDO_PENDIENTE(PK_CONJUNTO, PK_BLOQUE, PK_APTO, L_NUM, LN_ANIO);
                EXIT;
            END IF;
            IF L_NUM != 1 THEN
                L_NUM := L_NUM -1;
            ELSIF L_NUM = 1 THEN
                L_NUM := 12;
                LN_ANIO := LN_ANIO - 1;
            END IF;
        END LOOP;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PR_PAGAR_SALDO Ha ocurrido un error: '
            || SQLCODE
            || SQLERRM);
END PR_PAGAR_SALDO;
/

------------------------------------------------------ Procedimiento para recalcular los saldos pendientes de una cuenta de cobro.
CREATE OR REPLACE PROCEDURE PR_SALDO_PENDIENTE (
    PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
    PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
    PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
    PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
    PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE
)AS
    LS_PENDIENTE CUENTA_COBRO.SALDO_PENDIENTE%TYPE := 0;
    LN_MES       CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE;
    LN_ANIO      CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE;
BEGIN
    IF PN_MES = 12 THEN
        LN_MES := 1;
        LN_ANIO := PN_ANIO + 1;
    ELSE
        LN_MES := PN_MES + 1;
        LN_ANIO := PN_ANIO;
    END IF;
    LOOP
        IF LN_MES = 1 THEN
            SELECT
                SUM(SALDO_ACTUAL + SALDO_PENDIENTE) INTO LS_PENDIENTE
            FROM
                CUENTA_COBRO
            WHERE
                PERIODO_MES_CUENTA = 12
                AND PERIODO_ANIO_CUENTA = LN_ANIO-1;
        ELSE
            SELECT
                SUM(SALDO_ACTUAL + SALDO_PENDIENTE) INTO LS_PENDIENTE
            FROM
                CUENTA_COBRO
            WHERE
                PERIODO_MES_CUENTA = LN_MES - 1
                AND PERIODO_ANIO_CUENTA = LN_ANIO;
        END IF;
        IF LS_PENDIENTE IS NULL THEN
            EXIT;
        ELSIF LS_PENDIENTE < 0 THEN
            UPDATE CUENTA_COBRO
            SET
                SALDO_PENDIENTE = 0,
                SALDO_ACTUAL = SALDO_ACTUAL + LS_PENDIENTE
            WHERE
                COD_CONJUNTO = PK_CONJUNTO
                AND COD_BLOQUE = PK_BLOQUE
                AND COD_APARTAMENTO = PK_APTO
                AND PERIODO_MES_CUENTA = LN_MES
                AND PERIODO_ANIO_CUENTA = LN_ANIO;
            IF LN_MES != 1 THEN
                UPDATE CUENTA_COBRO
                SET
                    SALDO_ACTUAL = 0
                WHERE
                    COD_CONJUNTO = PK_CONJUNTO
                    AND COD_BLOQUE = PK_BLOQUE
                    AND COD_APARTAMENTO = PK_APTO
                    AND PERIODO_MES_CUENTA = LN_MES - 1
                    AND PERIODO_ANIO_CUENTA = LN_ANIO;
            ELSE
                UPDATE CUENTA_COBRO
                SET
                    SALDO_ACTUAL = 0
                WHERE
                    COD_CONJUNTO = PK_CONJUNTO
                    AND COD_BLOQUE = PK_BLOQUE
                    AND COD_APARTAMENTO = PK_APTO
                    AND PERIODO_MES_CUENTA = 12
                    AND PERIODO_ANIO_CUENTA = LN_ANIO - 1;
            END IF;
        ELSE
            UPDATE CUENTA_COBRO
            SET
                SALDO_PENDIENTE = LS_PENDIENTE
            WHERE
                COD_CONJUNTO = PK_CONJUNTO
                AND COD_BLOQUE = PK_BLOQUE
                AND COD_APARTAMENTO = PK_APTO
                AND PERIODO_MES_CUENTA = LN_MES
                AND PERIODO_ANIO_CUENTA = LN_ANIO;
        END IF;
        IF LN_MES != 12 THEN
            LN_MES := LN_MES + 1;
        ELSIF LN_MES = 12 THEN
            LN_MES := 1;
            LN_ANIO := LN_ANIO + 1;
        END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PR_SALDO_PENDIENTE Ha ocurrido un error: '
            || SQLCODE
            || SQLERRM);
END PR_SALDO_PENDIENTE;
/

------------------------------------------------------ Procedimiento para establecer en cero el saldo actual y el saldo pendiente de una cuenta de cobro
CREATE OR REPLACE PROCEDURE PR_INIT_SALDOS (
    PK_CONJUNTO IN CONJUNTO.COD_CONJUNTO%TYPE,
    PK_BLOQUE IN APARTAMENTO.COD_BLOQUE%TYPE,
    PK_APTO IN APARTAMENTO.COD_APARTAMENTO%TYPE,
    PN_MES IN CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE,
    PN_ANIO IN CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE
) AS
    LK_CUENTA CUENTA_COBRO.COD_CUENTA_COBRO%TYPE;
    LN_MES    CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE;
    LN_ANIO   CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE;
BEGIN
    IF PN_MES < 1 THEN
        LN_MES := 12;
        LN_ANIO := PN_ANIO - 1;
    ELSE
        LN_MES := PN_MES;
        LN_ANIO := PN_ANIO;
    END IF;
    LOOP
        SELECT
            MAX(COD_CUENTA_COBRO) INTO LK_CUENTA
        FROM
            CUENTA_COBRO
        WHERE
            COD_CONJUNTO = PK_CONJUNTO
            AND COD_BLOQUE = PK_BLOQUE
            AND COD_APARTAMENTO = PK_APTO
            AND PERIODO_MES_CUENTA = LN_MES
            AND PERIODO_ANIO_CUENTA = LN_ANIO;
        IF LK_CUENTA IS NULL THEN
            EXIT;
        ELSE
            UPDATE CUENTA_COBRO
            SET
                SALDO_ACTUAL = 0,
                SALDO_PENDIENTE = 0,
                VALOR_DESCUENTO = 0,
                VALOR_MORA = 0,
                ESTADO_CUENTA = 'Pagado'
            WHERE
                COD_CONJUNTO = PK_CONJUNTO
                AND COD_BLOQUE = PK_BLOQUE
                AND COD_APARTAMENTO = PK_APTO
                AND PERIODO_MES_CUENTA = LN_MES
                AND PERIODO_ANIO_CUENTA = LN_ANIO;
            IF LN_MES < 1 THEN
                LN_MES := 12;
                LN_ANIO := PN_ANIO - 1;
            ELSE
                LN_MES := LN_MES - 1;
            END IF;
        END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20001, 'PR_INIT_SALDOS Ha ocurrido un error: '
            || SQLCODE
            || SQLERRM);
END PR_INIT_SALDOS;
/


------------------------------------------------------ Procedimiento que calcula el valor de descuento o mora de las cuentas de cobro del último mes y lo inserta en la cuenta de cobro.
CREATE OR REPLACE PROCEDURE PR_CALC_DESC_MORA (
    PC_ERROR OUT INTEGER,
    PM_ERROR OUT VARCHAR
) IS
    LN_DIA_ACTUAL     INTEGER;
    LN_MES_ACTUAL     INTEGER;
    LN_ANIO_ACTUAL    INTEGER;
    LN_MES            CUENTA_COBRO.PERIODO_MES_CUENTA%TYPE;
    LN_ANIO           CUENTA_COBRO.PERIODO_ANIO_CUENTA%TYPE;
    LS_ACTUAL         CUENTA_COBRO.SALDO_ACTUAL%TYPE;
    LV_MORA           CUENTA_COBRO.VALOR_MORA%TYPE;
    LV_DESCUENTO      CUENTA_COBRO.VALOR_DESCUENTO%TYPE;
    LK_CUENTA         CUENTA_COBRO.COD_CUENTA_COBRO%TYPE;
    LE_INCONSISTENCIA EXCEPTION;
BEGIN
    FOR R_PERIODO IN (
        SELECT
            PERIODO_MES_CUENTA,
            PERIODO_ANIO_CUENTA
        FROM
            CONJUNTO     C,
            APARTAMENTO  A,
            CUENTA_COBRO CC
        WHERE
            CC.COD_APARTAMENTO = A.COD_APARTAMENTO
            AND CC.COD_BLOQUE = A.COD_BLOQUE
            AND CC.COD_CONJUNTO = A.COD_CONJUNTO
            AND A.COD_CONJUNTO = C.COD_CONJUNTO
    ) LOOP
        SELECT
            EXTRACT(DAY
        FROM
            CURRENT_DATE ),
            EXTRACT(MONTH FROM CURRENT_DATE ),
            EXTRACT(YEAR FROM CURRENT_DATE ) INTO LN_DIA_ACTUAL,
            LN_MES_ACTUAL,
            LN_ANIO_ACTUAL
        FROM
            DUAL;
        FOR R_SALDOS IN (
            SELECT
                C.COD_CONJUNTO,
                C.VALOR_TASA_MORA,
                C.VALOR_TASA_DESCUENTO,
                C.DIA_OPORTUNO,
                A.COD_BLOQUE,
                A.COD_APARTAMENTO,
                CC.COD_CUENTA_COBRO,
                CC.SALDO_ACTUAL,
                CC.SALDO_PENDIENTE,
                CC.VALOR_DESCUENTO,
                CC.VALOR_MORA,
                CC.PERIODO_MES_CUENTA,
                CC.PERIODO_ANIO_CUENTA
            FROM
                CONJUNTO     C,
                APARTAMENTO  A,
                CUENTA_COBRO CC
            WHERE
                CC.COD_APARTAMENTO = A.COD_APARTAMENTO
                AND CC.COD_BLOQUE = A.COD_BLOQUE
                AND CC.COD_CONJUNTO = A.COD_CONJUNTO
                AND A.COD_CONJUNTO = C.COD_CONJUNTO
                AND CC.PERIODO_MES_CUENTA = R_PERIODO.PERIODO_MES_CUENTA
                AND CC.PERIODO_ANIO_CUENTA = R_PERIODO.PERIODO_ANIO_CUENTA
        ) LOOP
            IF R_SALDOS.DIA_OPORTUNO < LN_DIA_ACTUAL AND R_SALDOS.PERIODO_MES_CUENTA = LN_MES_ACTUAL AND R_SALDOS.PERIODO_ANIO_CUENTA = LN_ANIO_ACTUAL THEN
                IF R_SALDOS.VALOR_MORA = 0 THEN
                    IF R_SALDOS.VALOR_DESCUENTO > 0 THEN
                        R_SALDOS.SALDO_ACTUAL := R_SALDOS.SALDO_ACTUAL + ( R_SALDOS.SALDO_ACTUAL * (R_SALDOS.VALOR_TASA_DESCUENTO / 100));
                    END IF;
                    LV_MORA := R_SALDOS.SALDO_ACTUAL * (R_SALDOS.VALOR_TASA_MORA / 100);
                    R_SALDOS.SALDO_ACTUAL := R_SALDOS.SALDO_ACTUAL + LV_MORA;
                    UPDATE CUENTA_COBRO
                    SET
                        SALDO_ACTUAL = R_SALDOS.SALDO_ACTUAL,
                        VALOR_MORA = LV_MORA,
                        ESTADO_CUENTA = 'En mora'
                    WHERE
                        COD_CUENTA_COBRO = R_SALDOS.COD_CUENTA_COBRO;
                END IF;
                COMMIT;
            ELSIF R_SALDOS.PERIODO_MES_CUENTA < LN_MES_ACTUAL AND R_SALDOS.PERIODO_ANIO_CUENTA <= LN_ANIO_ACTUAL THEN
                IF R_SALDOS.VALOR_MORA = 0 THEN
                    IF R_SALDOS.VALOR_DESCUENTO > 0 THEN
                        R_SALDOS.SALDO_ACTUAL := R_SALDOS.SALDO_ACTUAL + ( R_SALDOS.SALDO_ACTUAL * (R_SALDOS.VALOR_TASA_DESCUENTO / 100));
                    END IF;
                    LV_MORA := R_SALDOS.SALDO_ACTUAL * (R_SALDOS.VALOR_TASA_MORA / 100);
                    R_SALDOS.SALDO_ACTUAL := R_SALDOS.SALDO_ACTUAL + LV_MORA;
                    UPDATE CUENTA_COBRO
                    SET
                        SALDO_ACTUAL = R_SALDOS.SALDO_ACTUAL,
                        VALOR_MORA = LV_MORA,
                        ESTADO_CUENTA = 'En mora'
                    WHERE
                        COD_CUENTA_COBRO = R_SALDOS.COD_CUENTA_COBRO;
                END IF;
                COMMIT;
            ELSIF R_SALDOS.DIA_OPORTUNO >= LN_DIA_ACTUAL AND R_SALDOS.PERIODO_MES_CUENTA = LN_MES_ACTUAL AND R_SALDOS.PERIODO_ANIO_CUENTA = LN_ANIO_ACTUAL THEN
                IF R_SALDOS.VALOR_DESCUENTO = 0 THEN
                    LV_DESCUENTO := R_SALDOS.SALDO_ACTUAL * (R_SALDOS.VALOR_TASA_DESCUENTO / 100);
                    R_SALDOS.SALDO_ACTUAL := R_SALDOS.SALDO_ACTUAL - LV_DESCUENTO;
                    UPDATE CUENTA_COBRO
                    SET
                        SALDO_ACTUAL = R_SALDOS.SALDO_ACTUAL,
                        VALOR_DESCUENTO = LV_DESCUENTO,
                        ESTADO_CUENTA = 'Pendiente'
                    WHERE
                        COD_CUENTA_COBRO = R_SALDOS.COD_CUENTA_COBRO;
                END IF;
                COMMIT;
            ELSIF R_SALDOS.PERIODO_MES_CUENTA > LN_MES_ACTUAL OR R_SALDOS.PERIODO_ANIO_CUENTA > LN_ANIO_ACTUAL THEN
                IF R_SALDOS.VALOR_DESCUENTO = 0 THEN
                    LV_DESCUENTO := R_SALDOS.SALDO_ACTUAL * (R_SALDOS.VALOR_TASA_DESCUENTO / 100);
                    R_SALDOS.SALDO_ACTUAL := R_SALDOS.SALDO_ACTUAL - LV_DESCUENTO;
                    UPDATE CUENTA_COBRO
                    SET
                        SALDO_ACTUAL = R_SALDOS.SALDO_ACTUAL,
                        VALOR_DESCUENTO = LV_DESCUENTO,
                        ESTADO_CUENTA = 'Pendiente'
                    WHERE
                        COD_CUENTA_COBRO = R_SALDOS.COD_CUENTA_COBRO;
                END IF;
                COMMIT;
            ELSE
                LK_CUENTA := R_SALDOS.COD_CUENTA_COBRO;
                ROLLBACK;
                RAISE LE_INCONSISTENCIA;
            END IF;
 -- IF R_SALDOS.SALDO_ACTUAL = 0 AND R_SALDOS.SALDO_PENDIENTE = 0 THEN
 --     UPDATE CUENTA_COBRO
 --     SET
 --         VALOR_MORA = 0,
 --         VALOR_DESCUENTO = 0,
 --         ESTADO_CUENTA = 'Pagado'
 --     WHERE
 --         COD_CUENTA_COBRO = R_SALDOS.COD_CUENTA_COBRO;
 --     COMMIT;
 -- END IF;
            PR_SALDO_PENDIENTE(R_SALDOS.COD_CONJUNTO, R_SALDOS.COD_BLOQUE, R_SALDOS.COD_APARTAMENTO, R_PERIODO.PERIODO_MES_CUENTA, R_PERIODO.PERIODO_ANIO_CUENTA);
        END LOOP;
    END LOOP;
EXCEPTION
    WHEN LE_INCONSISTENCIA THEN
        PC_ERROR := 1;
        PM_ERROR := 'Hay inconsistencias en la cuenta de cobro código '
            || LK_CUENTA;
    WHEN OTHERS THEN
        PC_ERROR := 1;
        PM_ERROR := 'Error en el cálculo de descuento/mora en el saldo actual de una cuenta de cobro.';
        RAISE_APPLICATION_ERROR(-20001, 'PR_CALC_DESC_MORA Ha ocurrido un error: '
            || SQLCODE
            || SQLERRM);
END PR_CALC_DESC_MORA;
/