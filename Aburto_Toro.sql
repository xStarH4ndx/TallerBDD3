/*
--------TALLER 3 BDD-----------
Nombres:
	- Nicolas Aburto Lopez - 18758339-K - ICCI
	- Bruno Toro - 20864066-6 - ICCI
*/
-- Asegurarse de que PL/pgSQL esté habilitado
CREATE EXTENSION IF NOT EXISTS plpgsql;

-- Eliminar tablas si existen
DROP TABLE IF EXISTS Envio;
DROP TABLE IF EXISTS EmpresaTransporte;
DROP TABLE IF EXISTS DetalleCompra;
DROP TABLE IF EXISTS Compra;
DROP TABLE IF EXISTS Articulo;
DROP TABLE IF EXISTS Categoria;
DROP TABLE IF EXISTS Usuario;

/*--------------------------CREACION DE LAS TABLAS-----------------------*/
-- Crear tabla Usuario
CREATE TABLE Usuario (
    ID_usuario SERIAL PRIMARY KEY,
    Rut VARCHAR(12) UNIQUE NOT NULL,
    Nombre VARCHAR(50),
    Apellido VARCHAR(50),
    Contraseña VARCHAR(255),
    Tipo VARCHAR(15) NOT NULL CHECK (Tipo IN ('No registrado', 'Registrado', 'Proveedor')),
    Ciudad VARCHAR(50),
    Comuna VARCHAR(50),
    Calle VARCHAR(100),
    Numero VARCHAR(10)
);

-- Crear tabla Categoría
CREATE TABLE Categoria (
    ID_categoria SERIAL PRIMARY KEY,
    Nombre VARCHAR(50) NOT NULL,
    Descripcion TEXT
);

-- Crear tabla Artículo
CREATE TABLE Articulo (
    ID_articulo SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Descripcion TEXT,
    Precio DECIMAL(10, 2) NOT NULL,
    Color VARCHAR(30),
    Cantidad INT NOT NULL,
    Descuento DECIMAL(5, 2),
    ID_categoria INT NOT NULL,
    FOREIGN KEY (ID_categoria) REFERENCES Categoria(ID_categoria)
);

-- Crear tabla Compra
CREATE TABLE Compra (
    ID_compra SERIAL PRIMARY KEY,
    Fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ID_usuario INT,
    Rut_usuario_no_registrado VARCHAR(12),
    Ciudad_entrega VARCHAR(50),
    Comuna_entrega VARCHAR(50),
    Calle_entrega VARCHAR(100),
    Numero_entrega VARCHAR(10),
    Ciudad_retiro VARCHAR(50),
    Comuna_retiro VARCHAR(50),
    Calle_retiro VARCHAR(100),
    Numero_retiro VARCHAR(10),
    Total DECIMAL(10, 2) NOT NULL,
    Costo_envio DECIMAL(10, 2),
    FOREIGN KEY (ID_usuario) REFERENCES Usuario(ID_usuario)
);

-- Crear tabla DetalleCompra
CREATE TABLE DetalleCompra (
    ID_detalle SERIAL PRIMARY KEY,
    ID_compra INT NOT NULL,
    ID_articulo INT NOT NULL,
    Cantidad INT NOT NULL,
    Precio_unitario DECIMAL(10, 2) NOT NULL,
    Descuento DECIMAL(5, 2),
    FOREIGN KEY (ID_compra) REFERENCES Compra(ID_compra),
    FOREIGN KEY (ID_articulo) REFERENCES Articulo(ID_articulo)
);

-- Crear tabla EmpresaTransporte
CREATE TABLE EmpresaTransporte (
    ID_empresa SERIAL PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Direccion TEXT,
    Numero_envios_realizados INT,
    Correo VARCHAR(100),
    Numero_contacto VARCHAR(15)
);

-- Crear tabla Envío
CREATE TABLE Envio (
    ID_envio SERIAL PRIMARY KEY,
    ID_compra INT NOT NULL,
    ID_empresa INT NOT NULL,
    Costo_envio DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (ID_compra) REFERENCES Compra(ID_compra),
    FOREIGN KEY (ID_empresa) REFERENCES EmpresaTransporte(ID_empresa)
);

/*-------------------INSERCIONES----------------------------*/
--Insertar datos de prueba en Usuario
INSERT INTO Usuario (Rut, Nombre, Apellido, Contraseña, Tipo, Ciudad, Comuna, Calle, Numero) VALUES
('12345678-9', 'Juan', 'Perez', 'password123', 'Registrado', 'Santiago', 'Centro', 'Av. Libertador', '1234'),
('98765432-1', 'Maria', 'Gonzalez', 'password456', 'Proveedor', 'Valparaíso', 'Norte', 'Calle 1', '5678');

--Insertar datos de prueba en Categoria
INSERT INTO Categoria (Nombre, Descripcion) VALUES
('Electrónica', 'Dispositivos electrónicos'),
('Ropa', 'Vestimenta para todas las edades');

--Insertar datos de prueba en Articulo
INSERT INTO Articulo (Nombre, Descripcion, Precio, Color, Cantidad, Descuento, ID_categoria) VALUES
('Teléfono', 'Teléfono móvil', 59990, 'Negro', 50, 10, 1),
('Camiseta', 'Camiseta de algodón', 9990, 'Blanco', 100, 5, 2);



/*----------------FUNCIONES Y PROCEDIMIENTOS----------------------------*/
--1) Función para Registrar y Calcular el Monto Total de la Compra------
CREATE OR REPLACE FUNCTION calcular_total_compra(p_id_compra INT)
RETURNS DECIMAL AS $$
DECLARE
    v_total DECIMAL(10, 2);
    v_envio DECIMAL(10, 2);
    v_subtotal DECIMAL(10, 2);
    v_descuento DECIMAL(10, 2);
    v_es_registrado BOOLEAN;
BEGIN
    -- Calcular el subtotal de la compra
    SELECT SUM(dc.Cantidad * dc.Precio_unitario) INTO v_subtotal
    FROM DetalleCompra dc
    WHERE dc.ID_compra = p_id_compra;
    
    -- Verificar si el usuario es registrado
    SELECT u.Tipo = 'Registrado' INTO v_es_registrado
    FROM Compra c
    JOIN Usuario u ON c.ID_usuario = u.ID_usuario
    WHERE c.ID_compra = p_id_compra;
    
    -- Aplicar descuentos si el usuario es registrado
    IF v_es_registrado THEN
        SELECT SUM(dc.Cantidad * dc.Precio_unitario * (dc.Descuento / 100)) INTO v_descuento
        FROM DetalleCompra dc
        WHERE dc.ID_compra = p_id_compra;
    ELSE
        v_descuento := 0;
    END IF;
    
    -- Calcular el costo de envío
    IF v_es_registrado AND v_subtotal > 20000 THEN
        v_envio := 0;
    ELSE
        v_envio := v_subtotal * 0.12;
    END IF;
    
    -- Calcular el total
    v_total := v_subtotal - v_descuento + v_envio;
    
    -- Actualizar el total y costo de envío en la tabla Compra
    UPDATE Compra
    SET Total = v_total,
        Costo_envio = v_envio
    WHERE ID_compra = p_id_compra;
    
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

--2)Función para Simular una Compra---------------------------------------------
CREATE OR REPLACE FUNCTION simular_compra(p_id_usuario INT, p_productos INT[], p_cantidades INT[])
RETURNS INT AS $$
DECLARE
    v_id_compra INT;
    i INT;
BEGIN
    -- Crear una nueva compra
    INSERT INTO Compra (ID_usuario, Total, Costo_envio)
    VALUES (p_id_usuario, 0, 0)
    RETURNING ID_compra INTO v_id_compra;
    
    -- Agregar los productos a la compra
    FOR i IN 1..array_length(p_productos, 1) LOOP
        INSERT INTO DetalleCompra (ID_compra, ID_articulo, Cantidad, Precio_unitario, Descuento)
        SELECT v_id_compra, p_productos[i], p_cantidades[i], a.Precio, a.Descuento
        FROM Articulo a
        WHERE a.ID_articulo = p_productos[i];
    END LOOP;
    
    -- Calcular y registrar el total de la compra
    PERFORM calcular_total_compra(v_id_compra);
    
    RETURN v_id_compra;
END;
$$ LANGUAGE plpgsql;

--3) Procedimiento para Registrar Direcciones---------------------------------------
CREATE OR REPLACE PROCEDURE registrar_direcciones(p_id_compra INT, p_ciudad_entrega VARCHAR, p_comuna_entrega VARCHAR, p_calle_entrega VARCHAR, p_numero_entrega VARCHAR)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_usuario INT;
    v_ciudad_retiro VARCHAR;
    v_comuna_retiro VARCHAR;
    v_calle_retiro VARCHAR;
    v_numero_retiro VARCHAR;
BEGIN
    -- Obtener el usuario y la dirección del comprador
    SELECT c.ID_usuario INTO v_id_usuario
    FROM Compra c
    WHERE c.ID_compra = p_id_compra;
    
    -- Si la dirección de entrega es nula, usar la dirección del usuario registrado
    IF p_ciudad_entrega IS NULL OR p_comuna_entrega IS NULL OR p_calle_entrega IS NULL OR p_numero_entrega IS NULL THEN
        SELECT Ciudad, Comuna, Calle, Numero INTO p_ciudad_entrega, p_comuna_entrega, p_calle_entrega, p_numero_entrega
        FROM Usuario u
        WHERE u.ID_usuario = v_id_usuario;
    END IF;
    
    -- Obtener la dirección del vendedor (siempre usuario registrado)
    SELECT u.Ciudad, u.Comuna, u.Calle, u.Numero INTO v_ciudad_retiro, v_comuna_retiro, v_calle_retiro, v_numero_retiro
    FROM Usuario u
    JOIN DetalleCompra dc ON u.ID_usuario = dc.ID_articulo
    JOIN Compra c ON dc.ID_compra = c.ID_compra
    WHERE c.ID_compra = p_id_compra
    LIMIT 1;
    
    -- Actualizar la dirección de entrega y retiro en la compra
    UPDATE Compra
    SET Ciudad_entrega = p_ciudad_entrega,
        Comuna_entrega = p_comuna_entrega,
        Calle_entrega = p_calle_entrega,
        Numero_entrega = p_numero_entrega,
        Ciudad_retiro = v_ciudad_retiro,
        Comuna_retiro = v_comuna_retiro,
        Calle_retiro = v_calle_retiro,
        Numero_retiro = v_numero_retiro
    WHERE ID_compra = p_id_compra;
END;
$$;

--4)Funcion para filtrar productos por categoria---------------------------------
create or replace function filtrar_categoria(nombre_categoria varchar)
returns table(
	nombre varchar(100),
	descripcion text,
	precio decimal(10,2),
	color varchar(30),
	cantidad int
) as $$
begin
	return query
	select a.Nombre,a.Descripcion, a.Precio, a.Color,a.Cantidad
	from Articulo as a
	join Categoria as c on a.ID_categoria = c.ID_categoria
	where nombre_categoria = c.Nombre;
end;
$$ language plpgsql;

--5)Funcion para filtrar ventas por intervalo de fechas-------------------------
create or replace function filtrar_ventas(fecha_inicio text,fecha_fin text)
returns table(
	ID_compra int,
	Total decimal(10,2)
) as $$
begin
	return query
	select c.ID_compra,c.Total
	from Compra as c
	where c.Fecha between TO_DATE(fecha_inicio, 'DD-MM-YYYY') and TO_DATE(fecha_fin, 'DD-MM-YYYY');
end;
$$ language plpgsql;

--6) Retornar el porcentaje de compras-----
--7) Usuario con más descuento acumulado---


/*--------------------------Probar las Funciones y Procedimientos--------------------------------*/
--2)Simular una Compra
SELECT simular_compra(1, ARRAY[1, 2], ARRAY[1, 2]);

--3)Registrar Direcciones
CALL registrar_direcciones(1, 'Santiago', 'Centro', 'Av. Libertador', '1234');

--4) Filtrar productos por categoria
select * from filtrar_categoria('Ropa');--cambiar categoria

--5) filtrar ventas por fecha
select * from filtrar_ventas('01-01-2024', '31-12-2024');--modificar fechas

--6) Retornar el porcentaje de compras

--7) Usuario con más descuento acumulado




/*--------------------------------TRIGGERS---------------------------------*/
--1) Verificador de rut------------------------------------------------------------
--boleano del rut
create or replace function validar_rut(rut VARCHAR(12))
returns boolean as $$--me dirá si el rut es valido o no (true-false)
declare
    rut_numeros VARCHAR(10);
	verificador_recibido CHAR(1);
    verificador_calculado CHAR(1);
    suma INT := 0;
    resto INT;
    verificador_esperado VARCHAR(1);
begin
    --paso1: separar el rut
    rut_numeros := substring(rut from 1 for length(rut) - 1);
    verificador_recibido := substring(rut from length(rut));

    --paso2: calcular el verificador (predecir el que deberia ser)
    for i in reverse 1..length(rut_numeros) loop
        suma := suma + (substring(rut_numeros from i for 1)::INT * (i % 6 + 2));
    end loop;

    resto := suma % 11;

    if resto == 1 then
        verificador_esperado := 'K';
    elsif resto == 0 then
        verificador_esperado := '0';
    else
        verificador_esperado := cast(11 - resto as VARCHAR(1));
    end if;

    --pas3: verificar si es valido
    verificador_calculado := case when verificador_esperado = 'K' then 'K' else cast(resto as VARCHAR(1)) end;

    return verificador_calculado = verificador_recibido;
end;
$$ language plpgsql;

--funcion para comprobar el booleano del rut (si es valido o no)
create or replace function validar_usuario()
returns trigger as $$
begin
	if validar_rut(New.Rut) then
		return NEW;
	else
		raise exception 'El rut no es válido';
	end if;
end;
$$ language plpgsql;

--crear trigger
create trigger trigger_rut
before insert on Usuario
for each row
execute function validar_usuario();

--2) Verificación del stock

--trigger del stock
create or replace function verificar_stock_disponible()
returns trigger as $$
declare
	stock_disponible int;
begin
	select a.Cantidad into stock_disponible
	from Articulo as a
	where a.ID_articulo = new.ID_articulo;
	
	if stock_disponible >= new.Cantidad then
		update Articulo
		set Cantidad= Cantidad - new.cantidad
		where ID_articulo = new.ID_articulo;
	else
		raise exception 'No hay stock disponible';
	end if;
	
	return new;
end;
$$ language plpgsql;

create trigger verificar_stock
before insert on DetalleCompra
for each row
execute function verificar_stock_disponible();
   
