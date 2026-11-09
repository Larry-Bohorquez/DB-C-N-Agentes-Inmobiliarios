-- ==========================================================
-- C&N AGENTES INMOBILIARIOS
-- Funciones y triggers - PostgreSQL
-- Ejecutar después de database/schema.sql y antes de seed.sql.
-- ==========================================================

SET search_path TO public;

-- Trigger 1: validar CUSTOMER
CREATE OR REPLACE FUNCTION fn_validate_customer()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.BUDGET IS NOT NULL AND NEW.BUDGET < 0 THEN
        RAISE EXCEPTION 'El presupuesto no puede ser negativo';
    END IF;

    IF NEW.EMAIL IS NOT NULL AND POSITION('@' IN NEW.EMAIL) = 0 THEN
        RAISE EXCEPTION 'El correo % no es válido', NEW.EMAIL;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_customer ON CUSTOMER;
CREATE TRIGGER trg_validate_customer
BEFORE INSERT OR UPDATE ON CUSTOMER
FOR EACH ROW EXECUTE FUNCTION fn_validate_customer();

-- Trigger 2: validar PROPERTY
CREATE OR REPLACE FUNCTION fn_validate_property()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.OPERATION_TYPE NOT IN ('ARRIENDO', 'VENTA') THEN
        RAISE EXCEPTION 'Tipo de operación inválido: % (use ARRIENDO o VENTA)', NEW.OPERATION_TYPE;
    END IF;

    IF NEW.STATUS NOT IN ('DISPONIBLE', 'ARRENDADO', 'VENDIDO') THEN
        RAISE EXCEPTION 'Estado inválido: % (use DISPONIBLE, ARRENDADO o VENDIDO)', NEW.STATUS;
    END IF;

    IF NEW.AREA IS NULL OR NEW.AREA <= 0 THEN
        RAISE EXCEPTION 'El área debe ser mayor a 0';
    END IF;

    IF NEW.OPERATION_TYPE = 'VENTA' AND (NEW.SALE_PRICE IS NULL OR NEW.SALE_PRICE <= 0) THEN
        RAISE EXCEPTION 'Una propiedad en VENTA debe tener un precio de venta mayor a 0';
    END IF;

    IF NEW.OPERATION_TYPE = 'ARRIENDO' AND (NEW.RENTAL_RATE IS NULL OR NEW.RENTAL_RATE <= 0) THEN
        RAISE EXCEPTION 'Una propiedad en ARRIENDO debe tener un canon mayor a 0';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_property ON PROPERTY;
CREATE TRIGGER trg_validate_property
BEFORE INSERT OR UPDATE ON PROPERTY
FOR EACH ROW EXECUTE FUNCTION fn_validate_property();

-- Trigger 3: validar CONTRACT_RENTAL
CREATE OR REPLACE FUNCTION fn_validate_rental()
RETURNS TRIGGER AS $$
DECLARE
    v_operation VARCHAR;
    v_status VARCHAR;
BEGIN
    SELECT OPERATION_TYPE, STATUS
      INTO v_operation, v_status
      FROM PROPERTY
     WHERE ID = NEW.PROPERTY_ID
       AND NEIGHBORHOOD_ID = NEW.PROPERTY_NEIGHBORHOOD_ID;

    IF v_operation <> 'ARRIENDO' THEN
        RAISE EXCEPTION 'La propiedad % no es de tipo ARRIENDO', NEW.PROPERTY_ID;
    END IF;

    IF TG_OP = 'INSERT' AND v_status <> 'DISPONIBLE' THEN
        RAISE EXCEPTION 'La propiedad % no está disponible (estado: %)', NEW.PROPERTY_ID, v_status;
    END IF;

    IF NEW.DURATION IS NULL OR NEW.DURATION <= 0 THEN
        RAISE EXCEPTION 'La duración debe ser mayor a 0';
    END IF;

    IF NEW.RENTAL_VALUE IS NULL OR NEW.RENTAL_VALUE <= 0 THEN
        RAISE EXCEPTION 'El valor del arriendo debe ser mayor a 0';
    END IF;

    IF NEW.DEPOSIT_VALUE IS NOT NULL AND NEW.DEPOSIT_VALUE < 0 THEN
        RAISE EXCEPTION 'El depósito no puede ser negativo';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_rental ON CONTRACT_RENTAL;
CREATE TRIGGER trg_validate_rental
BEFORE INSERT OR UPDATE ON CONTRACT_RENTAL
FOR EACH ROW EXECUTE FUNCTION fn_validate_rental();

-- Trigger 4: validar CONTRACT_SALE
CREATE OR REPLACE FUNCTION fn_validate_sale()
RETURNS TRIGGER AS $$
DECLARE
    v_operation VARCHAR;
    v_status VARCHAR;
BEGIN
    SELECT OPERATION_TYPE, STATUS
      INTO v_operation, v_status
      FROM PROPERTY
     WHERE ID = NEW.PROPERTY_ID
       AND NEIGHBORHOOD_ID = NEW.PROPERTY_NEIGHBORHOOD_ID;

    IF v_operation <> 'VENTA' THEN
        RAISE EXCEPTION 'La propiedad % no es de tipo VENTA', NEW.PROPERTY_ID;
    END IF;

    IF TG_OP = 'INSERT' AND v_status <> 'DISPONIBLE' THEN
        RAISE EXCEPTION 'La propiedad % no está disponible (estado: %)', NEW.PROPERTY_ID, v_status;
    END IF;

    IF NEW.AGREED_VALUE IS NULL OR NEW.AGREED_VALUE <= 0 THEN
        RAISE EXCEPTION 'El valor acordado debe ser mayor a 0';
    END IF;

    IF NEW.DEED_DATE IS NOT NULL AND NEW.DEED_DATE < NEW.SALE_DATE THEN
        RAISE EXCEPTION 'La fecha de escritura no puede ser anterior a la fecha de venta';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_sale ON CONTRACT_SALE;
CREATE TRIGGER trg_validate_sale
BEFORE INSERT OR UPDATE ON CONTRACT_SALE
FOR EACH ROW EXECUTE FUNCTION fn_validate_sale();

-- Trigger 5: actualizar estado de la propiedad al crear contrato
CREATE OR REPLACE FUNCTION fn_update_property_status()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE PROPERTY
       SET STATUS = CASE TG_TABLE_NAME
                        WHEN 'contract_rental' THEN 'ARRENDADO'
                        ELSE 'VENDIDO'
                    END
     WHERE ID = NEW.PROPERTY_ID
       AND NEIGHBORHOOD_ID = NEW.PROPERTY_NEIGHBORHOOD_ID;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_rental_update_status ON CONTRACT_RENTAL;
CREATE TRIGGER trg_rental_update_status
AFTER INSERT ON CONTRACT_RENTAL
FOR EACH ROW EXECUTE FUNCTION fn_update_property_status();

DROP TRIGGER IF EXISTS trg_sale_update_status ON CONTRACT_SALE;
CREATE TRIGGER trg_sale_update_status
AFTER INSERT ON CONTRACT_SALE
FOR EACH ROW EXECUTE FUNCTION fn_update_property_status();

-- Trigger 6: validar CLAUSE (arriendo O venta, no ambos)
CREATE OR REPLACE FUNCTION fn_validate_clause()
RETURNS TRIGGER AS $$
DECLARE
    v_has_rental BOOLEAN;
    v_has_sale BOOLEAN;
BEGIN
    v_has_rental := NEW.CONTRACT_RENTAL_CUSTOMER_ID IS NOT NULL;
    v_has_sale   := NEW.CONTRACT_SALE_CUSTOMER_ID IS NOT NULL;

    IF v_has_rental AND v_has_sale THEN
        RAISE EXCEPTION 'La cláusula no puede pertenecer a un contrato de arriendo y de venta a la vez';
    END IF;

    IF NOT v_has_rental AND NOT v_has_sale THEN
        RAISE EXCEPTION 'La cláusula debe pertenecer a un contrato de arriendo o de venta';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_validate_clause ON CLAUSE;
CREATE TRIGGER trg_validate_clause
BEFORE INSERT OR UPDATE ON CLAUSE
FOR EACH ROW EXECUTE FUNCTION fn_validate_clause();

-- Trigger 7: auditoría de contratos (INSERT, UPDATE, DELETE)
CREATE OR REPLACE FUNCTION fn_audit_contract()
RETURNS TRIGGER AS $$
DECLARE
    v_row RECORD;
BEGIN
    IF TG_OP = 'DELETE' THEN
        v_row := OLD;
    ELSE
        v_row := NEW;
    END IF;

    INSERT INTO AUDIT_LOG (TABLE_NAME, OPERATION, DETAIL)
    VALUES (
        TG_TABLE_NAME,
        TG_OP,
        'cliente=' || v_row.CUSTOMER_ID || ', propiedad=' || v_row.PROPERTY_ID
    );

    RETURN v_row;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_rental ON CONTRACT_RENTAL;
CREATE TRIGGER trg_audit_rental
AFTER INSERT OR UPDATE OR DELETE ON CONTRACT_RENTAL
FOR EACH ROW EXECUTE FUNCTION fn_audit_contract();

DROP TRIGGER IF EXISTS trg_audit_sale ON CONTRACT_SALE;
CREATE TRIGGER trg_audit_sale
AFTER INSERT OR UPDATE OR DELETE ON CONTRACT_SALE
FOR EACH ROW EXECUTE FUNCTION fn_audit_contract();
