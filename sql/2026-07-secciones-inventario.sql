-- ================================================================
-- SECCIONES DEL INVENTARIO (julio 2026)
--
-- Reclasifica cada producto en la sección física del café donde se
-- cuenta (Vitrina de tortas, Limpieza, Sándwiches, etc.). La sección
-- se guarda en la columna `rubro` y aplica a TODAS las sedes.
--
-- La comparación ignora mayúsculas, tildes y espacios dobles, para
-- tolerar pequeñas diferencias de escritura.
-- ================================================================

-- Vitrina de tortas
update public.productos set rubro='Vitrina de tortas'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'cannolis chips chocolate','cannolis pistacho','cinnamon rolls','volcan de chocolate',
'donas frambuesa','donas nutella','donas oreo',
'medialuna manjar','medialuna membrillo','medialuna tradicional',
'pie de limon','pie de platano',
'trozo torta amor','trozo torta hojarasca','trozo torta tres leches','trozo torta matilda','trozo torta de zanahoria','trozo de tiramisu',
't. kutchen manzana','t. cheesecake mara','t. cheesecake fram.',
'muffin relleno arandano','muffin vainilla chips','muffin amapola','muffin de zanahoria','mini muffin',
'galleton red velvet','galleton pasas','galleton chips');

-- Limpieza
update public.productos set rubro='Limpieza'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'bidon alcohol liquido','bidon alcohol gel','bidon desengrasante','bidon lava loza','bidon lustramuebles',
'bidon de jabon','bidon desifectante virutex piso','bidon desinfectante virutex piso','bidon limpia vidrios',
'traperos humedos','nova','bolsa basura','guantes nitrilo','guantes plasticos','guante plastico',
'cofia (bolsas)','esponja','spontex','alusa plast (plastica)','alusa foil (metalica)');

-- Sándwiches
update public.productos set rubro='Sándwiches'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'sandwich serrano','sandwich mechada','sandwich apaltado','sandwich azapa','sandwich champinon',
'croissant jamon queso','selladitos jamon queso');

-- Mesones
update public.productos set rubro='Mesones'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'cafe grano 250 gr','cafe molido 250 gr','cafe cafetera','canela','limones','naranjas','palta',
'jengibre','crema chantilly','platano congelado','hielo','te de hoja','menta');

-- Congelador
update public.productos set rubro='Congelador'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'pan masa madre','pan masa madre integral','pan foccacia aceituna','pan foccacia cebolla',
'pizza de 4 quesos','pizza de serrano','pizza peperoni','pizza hawaiana','pizza champinon',
'pulpa frambuesa','pulpa frutilla','pulpa mango','pulpa maracuya','pulpa pina',
'helado de vainilla','helado de chocolate','helado de frutilla');

-- Té
update public.productos set rubro='Té'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'te verde lipton','te dilmah','te d. mango y straberry','te d. earl grey','te hoja perla norte',
'te hoja pure ceylon','te d. pure green','te d. caramel','te china green tea',
'te d. blueberry y vainilla','te d. rasberry','te d. limon','te sendero del te',
'te verde s matices','te manzanilla','te chai hoja');

-- Vitrina de dulces
update public.productos set rubro='Vitrina de dulces'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'alfajor artesanal','alfajor manjar coco','maicenitos','cachitos','macarrons','waffles');

-- Vitrina de bebidas
update public.productos set rubro='Vitrina de bebidas'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'agua con gas','agua sin gas','agua tonica','ginger ale',
'cocacola light','cocacola normal','cocacola zero','cocacola mini coca','cocacola mini sprite',
'fanta','fanta zero','sprite normal','sprite zero','soda lleno','soda vacio');

-- Mueble de mezclas
update public.productos set rubro='Mueble de mezclas'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'mezcla chai latte','chocolate','mezcla leche dorada','matcha','proteina','betalanina',
'syrup canela','syrup de mora','syrup de caramelo','syrup pequenos','syrup almendra',
'syrup amaretto','syrup coco','syrup menta','syrup vainilla',
'syrup amaretto en bodega','syrup coco en bodega','syrup menta en bodega','syrup vainilla en bodega',
'salsa de caramelo','salsa de chocolate','salsa frambuesa','salsa manjar',
'azucar blanca','azucar morena','azuar flor','azucar flor',
'galletas oreo','masmellow','mermelada','crema de coco','llamita kids','coco rayado',
'leche condensada','manjar colum 1kg');

-- Mueble de bolsas
update public.productos set rubro='Mueble de bolsas'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'bandeja carton s','bandeja carton m','bandejas cuadradas',
'bolsa kraft s','bolsa kraft m','bolsa kraft g','bolsa delivery','caja de pizza',
'manga tapa vaso grande','manga tapa vaso mediano','vaso mediano','vasos grande',
'vasos transparentes','tapas transparentes','porta vasos',
'tenedores','cucharas','revolvedores','collarines','bombillas',
'servilltas grandes','servilletas grandes','servilletas pequena','servilletas pequenas',
'mantequilla','clavo de olor','topin','endulzante','sticker','silicona horno');

-- Mueble de caja
update public.productos set rubro='Mueble de caja'
where translate(lower(regexp_replace(trim(producto),'\s+',' ','g')),'áéíóúñü','aeiounu') in (
'papel impresora termica','papel transbank','papel mantequilla','corchetes');

-- ================================================================
-- COMPROBACIÓN: productos que quedaron SIN sección oficial.
-- Si esta consulta devuelve filas, cópialas y mándaselas a Claude
-- para agregarlas a la sección correcta.
-- ================================================================
select sede, producto, rubro as seccion_actual
from public.productos
where activo='SÍ'
  and rubro not in ('Vitrina de tortas','Limpieza','Sándwiches','Mesones','Congelador','Té',
                    'Vitrina de dulces','Vitrina de bebidas','Mueble de mezclas','Mueble de bolsas','Mueble de caja')
order by sede, producto;
