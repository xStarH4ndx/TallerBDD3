PGDMP      !                |            taller3_bdd    16.2    16.2 I               0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false                       0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false                       0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false                       1262    51434    taller3_bdd    DATABASE     ~   CREATE DATABASE taller3_bdd WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'Spanish_Chile.1252';
    DROP DATABASE taller3_bdd;
                postgres    false            �            1255    51526    calcular_total_compra(integer)    FUNCTION     �  CREATE FUNCTION public.calcular_total_compra(p_id_compra integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
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
$$;
 A   DROP FUNCTION public.calcular_total_compra(p_id_compra integer);
       public          postgres    false            �            1255    51535 $   filtrar_categoria(character varying)    FUNCTION     �  CREATE FUNCTION public.filtrar_categoria(nombre_categoria character varying) RETURNS TABLE(nombre character varying, descripcion text, precio numeric, color character varying, cantidad integer)
    LANGUAGE plpgsql
    AS $$
begin
	return query
	select a.Nombre,a.Descripcion, a.Precio, a.Color,a.Cantidad
	from Articulo as a
	join Categoria as c on a.ID_categoria = c.ID_categoria
	where nombre_categoria = c.Nombre;
end;
$$;
 L   DROP FUNCTION public.filtrar_categoria(nombre_categoria character varying);
       public          postgres    false            �            1255    51529 .   filtrar_productos_categoria(character varying)    FUNCTION     �  CREATE FUNCTION public.filtrar_productos_categoria(nombre_categoria character varying) RETURNS TABLE(nombre character varying, descripcion text, precio numeric, color character varying, cantidad integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        a.Nombre,
        a.Descripcion,
        a.Precio,
        a.Color,
        a.Cantidad
    FROM Articulo AS a
    JOIN Categoria AS c ON c.ID_categoria= a.ID_categoria
    WHERE c.Nombre= nombre_categoria;
END;
$$;
 V   DROP FUNCTION public.filtrar_productos_categoria(nombre_categoria character varying);
       public          postgres    false            �            1255    51537    filtrar_ventas(text, text)    FUNCTION     D  CREATE FUNCTION public.filtrar_ventas(fecha_inicio text, fecha_fin text) RETURNS TABLE(id_compra integer, total numeric)
    LANGUAGE plpgsql
    AS $$
begin
	return query
	select c.ID_compra,c.Total
	from Compra as c
	where c.Fecha between TO_DATE(fecha_inicio, 'DD-MM-YYYY') and TO_DATE(fecha_fin, 'DD-MM-YYYY');
end;
$$;
 H   DROP FUNCTION public.filtrar_ventas(fecha_inicio text, fecha_fin text);
       public          postgres    false            �            1255    51528 j   registrar_direcciones(integer, character varying, character varying, character varying, character varying) 	   PROCEDURE       CREATE PROCEDURE public.registrar_direcciones(IN p_id_compra integer, IN p_ciudad_entrega character varying, IN p_comuna_entrega character varying, IN p_calle_entrega character varying, IN p_numero_entrega character varying)
    LANGUAGE plpgsql
    AS $$
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
 �   DROP PROCEDURE public.registrar_direcciones(IN p_id_compra integer, IN p_ciudad_entrega character varying, IN p_comuna_entrega character varying, IN p_calle_entrega character varying, IN p_numero_entrega character varying);
       public          postgres    false            �            1255    51527 -   simular_compra(integer, integer[], integer[])    FUNCTION     ]  CREATE FUNCTION public.simular_compra(p_id_usuario integer, p_productos integer[], p_cantidades integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
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
$$;
 j   DROP FUNCTION public.simular_compra(p_id_usuario integer, p_productos integer[], p_cantidades integer[]);
       public          postgres    false            �            1255    51540    validacion_usuario()    FUNCTION     �   CREATE FUNCTION public.validacion_usuario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if validar_rut(New.Rut) then
		return NEW;
	else
		raise exception 'El rut no es válido';
	end if;
end;
$$;
 +   DROP FUNCTION public.validacion_usuario();
       public          postgres    false            �            1255    51538    validar_rut(character varying)    FUNCTION     x  CREATE FUNCTION public.validar_rut(rut character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$--me dirá si el rut es valido o no (true-false)
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
$$;
 9   DROP FUNCTION public.validar_rut(rut character varying);
       public          postgres    false            �            1255    51541    validar_usuario()    FUNCTION     �   CREATE FUNCTION public.validar_usuario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
	if validar_rut(New.Rut) then
		return NEW;
	else
		raise exception 'El rut no es válido';
	end if;
end;
$$;
 (   DROP FUNCTION public.validar_usuario();
       public          postgres    false            �            1255    51544    verificar_stock()    FUNCTION     �  CREATE FUNCTION public.verificar_stock() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 (   DROP FUNCTION public.verificar_stock();
       public          postgres    false            �            1255    51545    verificar_stock_disponible()    FUNCTION     �  CREATE FUNCTION public.verificar_stock_disponible() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
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
$$;
 3   DROP FUNCTION public.verificar_stock_disponible();
       public          postgres    false            �            1259    52234    articulo    TABLE     '  CREATE TABLE public.articulo (
    id_articulo integer NOT NULL,
    nombre character varying(100) NOT NULL,
    descripcion text,
    precio numeric(10,2) NOT NULL,
    color character varying(30),
    cantidad integer NOT NULL,
    descuento numeric(5,2),
    id_categoria integer NOT NULL
);
    DROP TABLE public.articulo;
       public         heap    postgres    false            �            1259    52233    articulo_id_articulo_seq    SEQUENCE     �   CREATE SEQUENCE public.articulo_id_articulo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.articulo_id_articulo_seq;
       public          postgres    false    220                       0    0    articulo_id_articulo_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.articulo_id_articulo_seq OWNED BY public.articulo.id_articulo;
          public          postgres    false    219            �            1259    52225 	   categoria    TABLE     �   CREATE TABLE public.categoria (
    id_categoria integer NOT NULL,
    nombre character varying(50) NOT NULL,
    descripcion text
);
    DROP TABLE public.categoria;
       public         heap    postgres    false            �            1259    52224    categoria_id_categoria_seq    SEQUENCE     �   CREATE SEQUENCE public.categoria_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.categoria_id_categoria_seq;
       public          postgres    false    218                       0    0    categoria_id_categoria_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.categoria_id_categoria_seq OWNED BY public.categoria.id_categoria;
          public          postgres    false    217            �            1259    52248    compra    TABLE     Z  CREATE TABLE public.compra (
    id_compra integer NOT NULL,
    fecha timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    id_usuario integer,
    rut_usuario_no_registrado character varying(12),
    ciudad_entrega character varying(50),
    comuna_entrega character varying(50),
    calle_entrega character varying(100),
    numero_entrega character varying(10),
    ciudad_retiro character varying(50),
    comuna_retiro character varying(50),
    calle_retiro character varying(100),
    numero_retiro character varying(10),
    total numeric(10,2) NOT NULL,
    costo_envio numeric(10,2)
);
    DROP TABLE public.compra;
       public         heap    postgres    false            �            1259    52247    compra_id_compra_seq    SEQUENCE     �   CREATE SEQUENCE public.compra_id_compra_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.compra_id_compra_seq;
       public          postgres    false    222            	           0    0    compra_id_compra_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.compra_id_compra_seq OWNED BY public.compra.id_compra;
          public          postgres    false    221            �            1259    52261    detallecompra    TABLE     �   CREATE TABLE public.detallecompra (
    id_detalle integer NOT NULL,
    id_compra integer NOT NULL,
    id_articulo integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(10,2) NOT NULL,
    descuento numeric(5,2)
);
 !   DROP TABLE public.detallecompra;
       public         heap    postgres    false            �            1259    52260    detallecompra_id_detalle_seq    SEQUENCE     �   CREATE SEQUENCE public.detallecompra_id_detalle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.detallecompra_id_detalle_seq;
       public          postgres    false    224            
           0    0    detallecompra_id_detalle_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.detallecompra_id_detalle_seq OWNED BY public.detallecompra.id_detalle;
          public          postgres    false    223            �            1259    52278    empresatransporte    TABLE     �   CREATE TABLE public.empresatransporte (
    id_empresa integer NOT NULL,
    nombre character varying(100) NOT NULL,
    direccion text,
    numero_envios_realizados integer,
    correo character varying(100),
    numero_contacto character varying(15)
);
 %   DROP TABLE public.empresatransporte;
       public         heap    postgres    false            �            1259    52277     empresatransporte_id_empresa_seq    SEQUENCE     �   CREATE SEQUENCE public.empresatransporte_id_empresa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 7   DROP SEQUENCE public.empresatransporte_id_empresa_seq;
       public          postgres    false    226                       0    0     empresatransporte_id_empresa_seq    SEQUENCE OWNED BY     e   ALTER SEQUENCE public.empresatransporte_id_empresa_seq OWNED BY public.empresatransporte.id_empresa;
          public          postgres    false    225            �            1259    52287    envio    TABLE     �   CREATE TABLE public.envio (
    id_envio integer NOT NULL,
    id_compra integer NOT NULL,
    id_empresa integer NOT NULL,
    costo_envio numeric(10,2) NOT NULL
);
    DROP TABLE public.envio;
       public         heap    postgres    false            �            1259    52286    envio_id_envio_seq    SEQUENCE     �   CREATE SEQUENCE public.envio_id_envio_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.envio_id_envio_seq;
       public          postgres    false    228                       0    0    envio_id_envio_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.envio_id_envio_seq OWNED BY public.envio.id_envio;
          public          postgres    false    227            �            1259    52213    usuario    TABLE     A  CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    rut character varying(12) NOT NULL,
    nombre character varying(50),
    apellido character varying(50),
    "contraseña" character varying(255),
    tipo character varying(15) NOT NULL,
    ciudad character varying(50),
    comuna character varying(50),
    calle character varying(100),
    numero character varying(10),
    CONSTRAINT usuario_tipo_check CHECK (((tipo)::text = ANY ((ARRAY['No registrado'::character varying, 'Registrado'::character varying, 'Proveedor'::character varying])::text[])))
);
    DROP TABLE public.usuario;
       public         heap    postgres    false            �            1259    52212    usuario_id_usuario_seq    SEQUENCE     �   CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.usuario_id_usuario_seq;
       public          postgres    false    216                       0    0    usuario_id_usuario_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;
          public          postgres    false    215            E           2604    52237    articulo id_articulo    DEFAULT     |   ALTER TABLE ONLY public.articulo ALTER COLUMN id_articulo SET DEFAULT nextval('public.articulo_id_articulo_seq'::regclass);
 C   ALTER TABLE public.articulo ALTER COLUMN id_articulo DROP DEFAULT;
       public          postgres    false    220    219    220            D           2604    52228    categoria id_categoria    DEFAULT     �   ALTER TABLE ONLY public.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('public.categoria_id_categoria_seq'::regclass);
 E   ALTER TABLE public.categoria ALTER COLUMN id_categoria DROP DEFAULT;
       public          postgres    false    218    217    218            F           2604    52251    compra id_compra    DEFAULT     t   ALTER TABLE ONLY public.compra ALTER COLUMN id_compra SET DEFAULT nextval('public.compra_id_compra_seq'::regclass);
 ?   ALTER TABLE public.compra ALTER COLUMN id_compra DROP DEFAULT;
       public          postgres    false    221    222    222            H           2604    52264    detallecompra id_detalle    DEFAULT     �   ALTER TABLE ONLY public.detallecompra ALTER COLUMN id_detalle SET DEFAULT nextval('public.detallecompra_id_detalle_seq'::regclass);
 G   ALTER TABLE public.detallecompra ALTER COLUMN id_detalle DROP DEFAULT;
       public          postgres    false    224    223    224            I           2604    52281    empresatransporte id_empresa    DEFAULT     �   ALTER TABLE ONLY public.empresatransporte ALTER COLUMN id_empresa SET DEFAULT nextval('public.empresatransporte_id_empresa_seq'::regclass);
 K   ALTER TABLE public.empresatransporte ALTER COLUMN id_empresa DROP DEFAULT;
       public          postgres    false    225    226    226            J           2604    52290    envio id_envio    DEFAULT     p   ALTER TABLE ONLY public.envio ALTER COLUMN id_envio SET DEFAULT nextval('public.envio_id_envio_seq'::regclass);
 =   ALTER TABLE public.envio ALTER COLUMN id_envio DROP DEFAULT;
       public          postgres    false    227    228    228            C           2604    52216    usuario id_usuario    DEFAULT     x   ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);
 A   ALTER TABLE public.usuario ALTER COLUMN id_usuario DROP DEFAULT;
       public          postgres    false    215    216    216            �          0    52234    articulo 
   TABLE DATA           v   COPY public.articulo (id_articulo, nombre, descripcion, precio, color, cantidad, descuento, id_categoria) FROM stdin;
    public          postgres    false    220   �v       �          0    52225 	   categoria 
   TABLE DATA           F   COPY public.categoria (id_categoria, nombre, descripcion) FROM stdin;
    public          postgres    false    218   pw       �          0    52248    compra 
   TABLE DATA           �   COPY public.compra (id_compra, fecha, id_usuario, rut_usuario_no_registrado, ciudad_entrega, comuna_entrega, calle_entrega, numero_entrega, ciudad_retiro, comuna_retiro, calle_retiro, numero_retiro, total, costo_envio) FROM stdin;
    public          postgres    false    222   �w       �          0    52261    detallecompra 
   TABLE DATA           q   COPY public.detallecompra (id_detalle, id_compra, id_articulo, cantidad, precio_unitario, descuento) FROM stdin;
    public          postgres    false    224   Ex       �          0    52278    empresatransporte 
   TABLE DATA           }   COPY public.empresatransporte (id_empresa, nombre, direccion, numero_envios_realizados, correo, numero_contacto) FROM stdin;
    public          postgres    false    226   }x                  0    52287    envio 
   TABLE DATA           M   COPY public.envio (id_envio, id_compra, id_empresa, costo_envio) FROM stdin;
    public          postgres    false    228   �x       �          0    52213    usuario 
   TABLE DATA           x   COPY public.usuario (id_usuario, rut, nombre, apellido, "contraseña", tipo, ciudad, comuna, calle, numero) FROM stdin;
    public          postgres    false    216   �x                  0    0    articulo_id_articulo_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.articulo_id_articulo_seq', 2, true);
          public          postgres    false    219                       0    0    categoria_id_categoria_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.categoria_id_categoria_seq', 2, true);
          public          postgres    false    217                       0    0    compra_id_compra_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('public.compra_id_compra_seq', 1, true);
          public          postgres    false    221                       0    0    detallecompra_id_detalle_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.detallecompra_id_detalle_seq', 2, true);
          public          postgres    false    223                       0    0     empresatransporte_id_empresa_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.empresatransporte_id_empresa_seq', 1, false);
          public          postgres    false    225                       0    0    envio_id_envio_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.envio_id_envio_seq', 1, false);
          public          postgres    false    227                       0    0    usuario_id_usuario_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.usuario_id_usuario_seq', 2, true);
          public          postgres    false    215            S           2606    52241    articulo articulo_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.articulo
    ADD CONSTRAINT articulo_pkey PRIMARY KEY (id_articulo);
 @   ALTER TABLE ONLY public.articulo DROP CONSTRAINT articulo_pkey;
       public            postgres    false    220            Q           2606    52232    categoria categoria_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.categoria
    ADD CONSTRAINT categoria_pkey PRIMARY KEY (id_categoria);
 B   ALTER TABLE ONLY public.categoria DROP CONSTRAINT categoria_pkey;
       public            postgres    false    218            U           2606    52254    compra compra_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY public.compra
    ADD CONSTRAINT compra_pkey PRIMARY KEY (id_compra);
 <   ALTER TABLE ONLY public.compra DROP CONSTRAINT compra_pkey;
       public            postgres    false    222            W           2606    52266     detallecompra detallecompra_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.detallecompra
    ADD CONSTRAINT detallecompra_pkey PRIMARY KEY (id_detalle);
 J   ALTER TABLE ONLY public.detallecompra DROP CONSTRAINT detallecompra_pkey;
       public            postgres    false    224            Y           2606    52285 (   empresatransporte empresatransporte_pkey 
   CONSTRAINT     n   ALTER TABLE ONLY public.empresatransporte
    ADD CONSTRAINT empresatransporte_pkey PRIMARY KEY (id_empresa);
 R   ALTER TABLE ONLY public.empresatransporte DROP CONSTRAINT empresatransporte_pkey;
       public            postgres    false    226            [           2606    52292    envio envio_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY public.envio
    ADD CONSTRAINT envio_pkey PRIMARY KEY (id_envio);
 :   ALTER TABLE ONLY public.envio DROP CONSTRAINT envio_pkey;
       public            postgres    false    228            M           2606    52221    usuario usuario_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id_usuario);
 >   ALTER TABLE ONLY public.usuario DROP CONSTRAINT usuario_pkey;
       public            postgres    false    216            O           2606    52223    usuario usuario_rut_key 
   CONSTRAINT     Q   ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_rut_key UNIQUE (rut);
 A   ALTER TABLE ONLY public.usuario DROP CONSTRAINT usuario_rut_key;
       public            postgres    false    216            b           2620    52303    usuario trigger_rut    TRIGGER     s   CREATE TRIGGER trigger_rut BEFORE INSERT ON public.usuario FOR EACH ROW EXECUTE FUNCTION public.validar_usuario();
 ,   DROP TRIGGER trigger_rut ON public.usuario;
       public          postgres    false    245    216            c           2620    52304    detallecompra verificar_stock    TRIGGER     �   CREATE TRIGGER verificar_stock BEFORE INSERT ON public.detallecompra FOR EACH ROW EXECUTE FUNCTION public.verificar_stock_disponible();
 6   DROP TRIGGER verificar_stock ON public.detallecompra;
       public          postgres    false    224    229            \           2606    52242 #   articulo articulo_id_categoria_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.articulo
    ADD CONSTRAINT articulo_id_categoria_fkey FOREIGN KEY (id_categoria) REFERENCES public.categoria(id_categoria);
 M   ALTER TABLE ONLY public.articulo DROP CONSTRAINT articulo_id_categoria_fkey;
       public          postgres    false    218    4689    220            ]           2606    52255    compra compra_id_usuario_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.compra
    ADD CONSTRAINT compra_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);
 G   ALTER TABLE ONLY public.compra DROP CONSTRAINT compra_id_usuario_fkey;
       public          postgres    false    4685    222    216            ^           2606    52272 ,   detallecompra detallecompra_id_articulo_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.detallecompra
    ADD CONSTRAINT detallecompra_id_articulo_fkey FOREIGN KEY (id_articulo) REFERENCES public.articulo(id_articulo);
 V   ALTER TABLE ONLY public.detallecompra DROP CONSTRAINT detallecompra_id_articulo_fkey;
       public          postgres    false    220    4691    224            _           2606    52267 *   detallecompra detallecompra_id_compra_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.detallecompra
    ADD CONSTRAINT detallecompra_id_compra_fkey FOREIGN KEY (id_compra) REFERENCES public.compra(id_compra);
 T   ALTER TABLE ONLY public.detallecompra DROP CONSTRAINT detallecompra_id_compra_fkey;
       public          postgres    false    224    4693    222            `           2606    52293    envio envio_id_compra_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.envio
    ADD CONSTRAINT envio_id_compra_fkey FOREIGN KEY (id_compra) REFERENCES public.compra(id_compra);
 D   ALTER TABLE ONLY public.envio DROP CONSTRAINT envio_id_compra_fkey;
       public          postgres    false    228    222    4693            a           2606    52298    envio envio_id_empresa_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.envio
    ADD CONSTRAINT envio_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.empresatransporte(id_empresa);
 E   ALTER TABLE ONLY public.envio DROP CONSTRAINT envio_id_empresa_fkey;
       public          postgres    false    4697    228    226            �   b   x�3�I�9�2-?/�R�=��,3������@����/5�(��Ԁ��5�2�tN��,N-I�3RRs��So��it�I�K�j3�4�b���� 	{#      �   U   x�3�t�IM.):�9/39��%�� �8�$�,�X!!�_�e��_���Z\����W��P�X��P���X��ĩ)�)��\1z\\\ � �      �   `   x�3�4202�50�52W04�22�25�34007�4���N�+�LL��tN�+)��t,�S��LJ-*IL�/�4426!J���������������� � c      �   (   x�3�4CSKKK=NC�e2B��)H0F��� �[      �      x������ � �             x������ � �      �   �   x�M�M
�0FדS�-��]J��WnF:�@ȔI��;y
/f����{�Ӡ��M;8<��@B+����e�.4G�+�`pb��a�-Yr4���\*��m�,�T�	� �٭h�����B��nhg��=Ù%�h-%�c�)��@4(     