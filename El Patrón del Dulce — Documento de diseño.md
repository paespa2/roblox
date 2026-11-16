# El Patrón del Dulce — Documento de diseño

Nov 15, 2026 · @paespa

## Visión y enfoque

El Patrón del Dulce es un tycoon de acción para Roblox donde construyes un imperio clandestino de dulces en una ciudad que prohibió el azúcar. Es una parodia del género de "ascenso del capo": toma su estructura (empezar de cero, crecer, ser perseguido, volverse leyenda) y la cambia por arequipe, gomitas y una Policía Dental.

- **Género:** tycoon con entregas, persecuciones y territorios.
- **Tono:** comedia absurda y colorida. Nadie muere: te "confiscan la carga" y te mandan al dentista.
- **Jugadores:** de 1 a 20 por servidor, solo o en banda.
- **Sesión típica:** de 10 a 20 minutos, con motivos para volver varias veces al día.
- **Qué lo diferencia:** ambientación colombiana (barrios en ladera, chivas, tiendas de barrio, dulces típicos) en un género donde casi todo es genérico.

La fantasía que vende es pasar de vender bombones en el recreo a ser el dulcero más buscado del país.

## Reglas de contenido

El juego parodia un género, no a una persona: esa es la línea que lo mantiene dentro de las [normas de Roblox](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct), que vetan drogas, criminales reales y eventos reales sensibles.

| Regla | Sí | No |
| --- | --- | --- |
| Personajes | Capo, rivales y policías inventados | Pablo Escobar, sus socios, o alguien reconocible por aspecto o frases |
| Lugares | Ciudad ficticia con sabor paisa | Medellín real, Hacienda Nápoles, La Catedral |
| Mercancía | Dulces de colores con forma y envoltura | Polvos blancos, bloques empacados, hojas, pastillas |
| Historia | El arco genérico del género | Atentados, asesinatos o hechos históricos, ni siquiera "en versión dulce" |
| Violencia | Pistolas de crema, bombas de confeti, confiscaciones | Sangre, ejecuciones, armas realistas |
| Nombre y miniatura | "El Patrón del Dulce" con arte caricaturesco | Etiquetas como "narco", "cartel" o "Escobar" para atraer búsquedas |

La prueba práctica: si alguien ve una captura y piensa en una persona o un hecho real, hay que cambiarlo.

## Historia por capítulos

La campaña son 10 capítulos, y cada uno se cierra con un logro que desbloquea el sistema siguiente. Así el jugador aprende una mecánica nueva por capítulo y siempre ve cuál es su próximo paso.

| # | Capítulo | Qué haces | Logro que lo cierra | Desbloquea |
| --- | --- | --- | --- | --- |
| 1 | El recreo | Vendes bombones en el colegio a escondidas del coordinador | "Primer bombón": vende 50 dulces | Bicicleta de reparto |
| 2 | La esquina | Convences a las tiendas del barrio de vender tu producto | "Dueño de la cuadra": controla 3 tiendas | Primera cocina clandestina |
| 3 | La cocina de la abuela | Produces arequipe y panelitas con recetas propias | "Receta secreta": domina 3 recetas | Moto |
| 4 | La ruta | Cruzas retenes de la Policía Dental con la carga escondida | "Ni una caries": 10 entregas sin que te atrapen | Escondites en vehículos |
| 5 | La banda | Reclutas repartidores y cocineros | "Los Golosos": banda de 5 miembros | Bodegas |
| 6 | La guerra del azúcar | La Banda del Chicle quiere tus rutas | "Aquí mando yo": gana 5 defensas de bodega | Territorios |
| 7 | La finca | Compras tus dos primeras fincas y levantas la mansión con parque de diversiones de dulce | "Finca La Melcocha": termina la mansión | Avioneta |
| 8 | El puente aéreo | Exportas a otras ciudades del mapa | "Sin fronteras": abre 3 ciudades | Dulces legendarios |
| 9 | El más buscado | El alcalde antiazúcar envía al Comandante Muelas, el jefe final | "Cinco estrellas": escapa de la gran persecución | Renacimiento |
| 10 | La leyenda | Te retiras y tu heredero empieza de nuevo con ventajas | "El Patrón del Dulce": completa tu primer renacimiento | Modo infinito |

### Logros paralelos

Son insignias que no bloquean la campaña y dan metas a los que ya la terminaron:

- **Coleccionista:** fabrica los 30 dulces del recetario.
- **Fantasma:** 100 entregas seguidas sin subir de una estrella.
- **Buen vecino:** regala 500 dulces a otros jugadores.
- **Magnate:** junta tu primer millón.
- **Diente de oro:** véncele una persecución al Comandante Muelas sin vehículo.

## Personajes

El reparto es original: 12 personajes con nombres de dulce o de odontología, construidos sobre los papeles típicos del género. Ninguno parodia el nombre, el apodo ni la historia de una persona real o de un personaje de una serie.

| Personaje | Papel | Aparece en |
| --- | --- | --- |
| El Patrón | El jugador, con avatar y apodo propios | Todo el juego |
| Doña Melcocha | La abuela: enseña las recetas y da los encargos del tutorial | Capítulos 1 a 3 |
| Don Ábaco | El tendero del barrio: lleva las cuentas y explica la economía | Capítulo 2 en adelante |
| Bombombún | Primer repartidor de la banda, torpe y leal | Capítulo 5 |
| Maestro Tuerca | Mecánico: mejora vehículos y arma los escondites | Capítulo 4 |
| Capitán Merengue | Piloto de la avioneta, le tiene miedo a las alturas | Capítulo 8 |
| Lola Paleta | Reportera del periódico del colegio: publica tus hazañas y sube tu fama | Encargos diarios |
| La Chiclosa | Jefa de la Banda del Chicle, rival principal | Capítulo 6 |
| Don Mentol | Jefe de Los Mentolados, que venden mentas sin azúcar y están aliados con el alcalde | Guerra de territorios |
| Alcalde Apio | El que prohibió el azúcar; villano de la historia | Capítulos 1 y 9 |
| Comandante Muelas | Jefe de la Policía Dental y jefe final | Capítulo 9 |
| Doctor Sarro | Director del Internado Sin Azúcar | La cárcel |

### Regla para crear más

- El nombre sale de un dulce, un ingrediente o un término dental.
- El personaje se define por su papel en el juego y un rasgo cómico propio.
- Si el nombre o el apodo recuerda a alguien real o a un personaje de una serie, se descarta.

## Bucle principal

Cada vuelta del bucle dura entre 3 y 5 minutos y termina con algo comprado, que es lo que invita a dar "una vuelta más".

1. **Producir.** Las cocinas fabrican dulces solas; tú eliges la receta y recoges la producción.
2. **Cargar.** Decides cuánto llevar: más carga da más ganancia, pero el vehículo va más lento y llama más la atención.
3. **Mover.** Manejas hasta la tienda o el barrio que pidió el dulce, esquivando retenes y patrullas.
4. **Vender.** Cobras según la demanda del día y sube tu fama en ese barrio.
5. **Huir.** Cada venta suma estrellas de búsqueda; si te atrapan pierdes la carga que llevas, nunca lo ya ganado, y con 3 estrellas o más vas al Internado Sin Azúcar.
6. **Reinvertir.** Mejoras cocina, vehículo o bodega, y el siguiente viaje rinde más.

La decisión que da tensión es la del paso 2: arriesgar un viaje grande o hacer varios pequeños y seguros.

## Rutina diaria y semanal

El jugador siempre tiene algo pendiente en tres escalas: algo para ahora, algo para hoy y algo para esta semana. Los sistemas premian volver, pero no castigan faltar.

| Sistema | Frecuencia | Qué pide | Premio |
| --- | --- | --- | --- |
| Hora del recreo | Cada hora en punto, 10 minutos | Vender en el colegio mientras dura | Ventas al doble |
| Tienda del contrabandista | Rota cada 4 horas | Revisar y comprar | Recetas, piezas y cosméticos escasos |
| Producción en ausencia | Se llena en 8 horas | Entrar a recoger la bodega | Dulces acumulados mientras no jugabas |
| Dulce del día | Diaria | Fabricar y vender el dulce en demanda | Precio triple para ese dulce |
| Tres encargos | Diaria | Tareas cortas: "entrega 20 gomitas", "escapa con 3 estrellas" | Monedas y puntos del pase |
| Racha de entrada | Diaria, ciclo de 7 días | Entrar al juego | Premio creciente; el día 7 da un cofre grande |
| Contrato de banda | Semanal | Meta compartida entre todos los miembros | Mejora permanente para la bodega común |
| Guerra de territorios | Sábado y domingo | Conquistar y defender barrios contra otras bandas | Ingreso pasivo del barrio toda la semana |
| Pase de temporada | Cada 6 semanas | Subir niveles con encargos | Vehículos, atuendos y un dulce legendario |
| Dulce de temporada | Mensual | Evento temático | Receta exclusiva: natilla y buñuelos en diciembre |

### Reglas para que enganche sin frustrar

- **La racha no se rompe a la primera.** Un "comodín" semanal perdona un día sin entrar.
- **El tope de 8 horas es la razón para volver.** Quien entra mañana y noche aprovecha toda la producción.
- **Los encargos toman 10 minutos en total.** Quien solo tiene un rato igual siente que avanzó.
- **Al salir, el juego muestra lo que viene.** Por ejemplo: "Tu bodega estará llena en 6 horas" y "La tienda rota en 40 minutos".

## Economía y progresión

Hay tres recursos y cada uno responde a una pregunta distinta del jugador. Todos los números de esta sección son valores de partida para ajustar en pruebas.

| Recurso | Cómo se gana | En qué se gasta |
| --- | --- | --- |
| Pesos dulces | Vendiendo | Cocinas, vehículos, bodegas, mansión |
| Fama | Entregas, logros, territorios | No se gasta: sube tu rango y abre capítulos |
| Azúcar dorada | Racha, pase, eventos, o con Robux | Cosméticos, recetas raras, acelerar producción |

### Niveles de dulces

| Nivel | Dulces | Se abre en | Valor por unidad |
| --- | --- | --- | --- |
| Común | Bombones, chicles, gomitas | Capítulo 1 | 1 |
| Casero | Arequipe, panelitas, bocadillo | Capítulo 3 | 5 |
| Fino | Chocolatinas, algodón de azúcar, obleas | Capítulo 5 | 25 |
| Exportación | Cajas surtidas, trufas | Capítulo 8 | 120 |
| Legendario | Uno por temporada | Eventos y pase | 600 |

### Mejoras

- **Cocina:** velocidad de producción y número de recetas activas.
- **Vehículo:** capacidad, velocidad y escondites. El orden es bicicleta, moto, camioneta, chiva y avioneta.
- **Bodega:** cuánto se acumula mientras no juegas.
- **Banda:** repartidores que hacen entregas pequeñas solos.
- **Mansión:** decoración que da bonos pasivos pequeños y sirve para presumir.

### Renacimiento

Al terminar el capítulo 9 puedes "retirarte". Pierdes pesos, cocinas y vehículos, y conservas recetas, cosméticos y mansión. A cambio, cada renacimiento suma un multiplicador permanente de ganancias de 1,5 y abre una ciudad nueva. Es lo que le da vida al juego después de la campaña.

## Fincas

El jugador llega a tener 8 fincas, cada una en una región distinta y con un ingrediente propio. Son la cadena de suministro del imperio: sin su ingrediente, una receta cuesta el doble de producir.

| Finca | Región | Produce | Sirve para | Se abre en |
| --- | --- | --- | --- | --- |
| La Melcocha | Montaña | Nada: es la base | Mansión, parque de dulce, bodega central | Capítulo 7 |
| El Ordeño | Altiplano lechero | Leche | Arequipe y panelitas | Capítulo 7 |
| La Molienda | Valle cañero | Panela y azúcar | Base de casi todas las recetas | Capítulo 8 |
| El Guayabal | Tierra caliente | Guayaba y frutas | Bocadillo y gomitas | Capítulo 8 |
| El Cacaotal | Selva | Cacao | Chocolatinas y trufas | Renacimiento 1 |
| La Colmena | Páramo | Miel | Obleas y dulces finos | Renacimiento 2 |
| El Tinto | Zona cafetera | Café | Dulces de café para exportación | Renacimiento 3 |
| El Algodón | Llanos | Nada: tiene pista | Hangar de avionetas y rutas largas | Renacimiento 4 |

### Cómo funcionan

- **Cosecha diaria.** Cada finca acumula su ingrediente mientras no juegas, con el mismo tope de 8 horas. Pasar a recoger por todas es parte de la rutina del día.
- **Cinco niveles de mejora.** Cada nivel sube la producción y agrega una construcción visible: establo, trapiche, secadero, bodega.
- **Trabajadores.** Se contratan y se asignan a cosechar, vigilar o transportar.
- **Inspección sanitaria.** De vez en cuando la Policía Dental revisa una finca; tienes un minuto para esconder la producción en la despensa secreta.
- **Asaltos.** En modo competitivo, otra banda puede intentar robar la cosecha. Se defiende con trampas y con las armas de dulce.
- **Decoración.** Cada finca se personaliza y se puede visitar, igual que la mansión.

Los nombres y las regiones son inventados. Ninguna finca copia una propiedad real ni lleva zoológico, que es justo el rasgo que la haría reconocible.

## La cárcel: el Internado Sin Azúcar

Cuando la Policía Dental te atrapa con 3 estrellas o más, vas al Internado Sin Azúcar, un reformatorio dental inventado donde solo sirven brócoli. Es la cárcel típica del género de policías y ladrones, no la recreación de ninguna prisión ni de ningún hecho real.

| Salida | Cómo funciona | Costo |
| --- | --- | --- |
| Cumplir la condena | 1 minuto por estrella; hacer tareas, como cepillar muelas gigantes, la acorta | Tiempo, máximo 5 minutos |
| Pagar la fianza | Sales de inmediato | Pesos dulces, más caro con cada estrella |
| Fugarte | Minijuego con tres rutas: la lavandería, el túnel de la cocina o disfrazarte de dentista | Si fallas, la condena sube 1 minuto |
| Rescate | Tu banda llega de afuera con un vehículo y abre el portón con dinamita de piñata | Sube las estrellas de todos los que ayudan |

### Qué pasa mientras estás adentro

- Tus cocinas y fincas siguen produciendo, pero nadie hace entregas hasta que salgas.
- Hay un mercado de contrabando entre internos: cambias dulces escondidos por herramientas para la fuga.
- Cada fuga lograda suma para el logro "Fuga dulce", y la primera es parte del capítulo 9.

### Límites

- El internado no puede parecerse a una prisión real: nada de cárcel de lujo construida por el propio capo, ni entregas pactadas con el gobierno, ni fechas o lugares reales.
- Los guardias son dentistas y enfermeros caricaturescos, sin armas realistas.

## Combate: armas y explosiones

El juego sí tiene armas y explosiones, todas hechas de dulce: se disparan, suenan y revientan en grande, pero sueltan confeti y espuma en vez de daño realista. Eso da la acción que piden las persecuciones y mantiene el juego abierto al público joven de Roblox.

| Arma | Tipo | Efecto | Se abre en |
| --- | --- | --- | --- |
| Cauchera de gomitas | Inicial, a distancia | Aturde 1 segundo | Capítulo 1 |
| Pistola de crema | A distancia | Tapa el parabrisas de la patrulla | Capítulo 4 |
| Escopeta de chicle | Corta distancia | Pega al rival al piso 3 segundos | Capítulo 5 |
| Mina de caramelo | Trampa | Frena en seco al vehículo que la pisa | Capítulo 5 |
| Granada de gaseosa | Explosivo | Estalla en espuma y empuja a todos en el área | Capítulo 6 |
| Bazuca de algodón | Explosivo | Nube rosada que deja sin visión una zona | Capítulo 7 |
| Dinamita de piñata | Explosivo pesado | Revienta retenes, barricadas y puertas de bodega | Capítulo 8 |
| Cañón de la chiva | Montado en vehículo | Dispara bombones gigantes en persecución | Capítulo 9 |

### Cómo funciona

- **La munición son tus dulces.** Cada disparo gasta mercancía, así que pelear cuesta ganancias y hay que decidir cuándo vale la pena.
- **Nadie muere.** El jugador vencido queda "empalagado", suelta parte de la carga y reaparece en el consultorio del dentista.
- **Los vehículos se averían.** Echan humo de colores y quedan fuera unos segundos, sin fuego ni restos.
- **Las explosiones cambian el terreno.** Abren atajos, tumban barricadas y dejan charcos pegajosos que frenan a quien pase.
- **Dónde se usa:** persecuciones, asalto de rutas, defensa de bodegas, guerra de territorios y la pelea contra el Comandante Muelas.

### Límites

- Los explosivos solo sirven contra retenes, patrullas, vehículos rivales y bodegas. No hay misiones de volar edificios ni de atacar a gente de la ciudad.
- Nada de armas con aspecto real, sangre ni cuerpos. Eso sube la clasificación de madurez del juego y le quita a los jugadores más jóvenes.
- En el equipo: Sistemas hace el sistema de armas, Entorno los modelos y efectos, y Economía el daño, el costo en dulces y los tiempos.

## Social y competencia

Jugar con otros debe rendir más que jugar solo, porque los amigos son la razón más fuerte para volver.

- **Bandas:** hasta 10 jugadores con bodega común, contrato semanal y colores propios.
- **Entregas en convoy:** llevar carga junto a un compañero da un bono a los dos.
- **Asalto de rutas:** puedes interceptar la carga de otra banda. Solo aplica a quien activó el modo competitivo, para no espantar a los jugadores tranquilos.
- **Roles en persecución:** un jugador maneja y otro lanza crema o confeti para frenar patrullas.
- **Tablas:** fama semanal por servidor y global, y tabla de bandas por territorios.
- **Intercambio:** las recetas y los dulces legendarios se pueden cambiar entre jugadores.
- **Visitas:** cualquiera puede entrar a ver tu mansión y dejar un "me gusta" que te da fama.

## Monetización

El juego es gratis y se puede terminar sin pagar; el Robux compra comodidad y apariencia, no victorias.

| Producto | Tipo | Qué da |
| --- | --- | --- |
| VIP | Gamepass | Etiqueta, atuendo exclusivo y un encargo diario extra |
| Segunda cocina activa | Gamepass | Producir dos recetas a la vez |
| Bodega ampliada | Gamepass | El tope de ausencia sube de 8 a 12 horas |
| Vehículos de colección | Gamepass | Chiva dorada, moto de caramelo: solo apariencia |
| Pase de temporada premium | Producto por temporada | Segunda fila de premios del pase |
| Azúcar dorada | Producto repetible | Paquetes de la moneda especial |
| Comodín de racha | Producto repetible | Perdona un día adicional sin entrar |

Dos cosas que conviene evitar: cajas aleatorias pagadas y cualquier ventaja de pago en el asalto de rutas, porque los jugadores que no pagan dejan de competir y se van.

## Equipo de 3: quién hace qué

El equipo se divide en tres áreas sin solapes: Entorno, Economía y Sistemas. Cada integrante es dueño de una, tiene la última palabra en ella y mantiene un "contrato" que los otros dos consultan.

### Quién es quién

- **Pablo: Sistemas.** Escribe todo el código, monta el repositorio y configura los cinco agentes. Su primera entrega es el bucle base: producir, cargar, vender y guardar datos.
- **Andrés: Entorno.** Construye el mapa y modela dulces, armas, vehículos y personajes. Su primera entrega es un barrio con una cocina, 3 dulces, la bicicleta y la moto.
- **Santiago: Economía.** Define los números, los encargos, las pantallas y lleva las pruebas y la publicación. Su primera entrega es la tabla de datos inicial y los bocetos de la interfaz.

La asignación es un punto de partida: si alguno maneja mejor otra área, se intercambian los nombres y el resto del documento sigue igual.

| Área | Es dueño de | No decide | Contrato que mantiene |
| --- | --- | --- | --- |
| **Entorno: Andrés** | Mapa, edificios, vehículos, personajes, animaciones, efectos visuales, sonido, iluminación, arte del icono y las miniaturas | Precios, reglas ni código | Catálogo de objetos |
| **Economía: Santiago** | Precios, tiempos, niveles de dulces, mejoras, renacimiento, encargos, racha, pase, requisitos de capítulos y logros, daño y costo de las armas, monetización, diseño de pantallas y textos, pruebas y publicación | Cómo se programa ni cómo se ve el mundo | Tabla de datos |
| **Sistemas: Pablo** | Todo el código: bucle de juego, guardado, Policía Dental, combate, conducción, sistemas diarios, bandas, interfaz funcionando, protección contra trampas | Los números ni el aspecto | Lista de eventos |

### Fronteras entre áreas

Estos son los puntos donde dos áreas se tocan, que es donde nacen las discrepancias. En cada uno hay una sola persona que decide.

| Punto de contacto | Decide | Ejecutan |
| --- | --- | --- |
| Interfaz | Economía: qué muestra cada pantalla y sus textos | Sistemas la programa; Entorno aporta los iconos |
| Armas | Economía: daño, alcance y costo en dulces | Entorno hace modelo y efectos; Sistemas las programa |
| Vehículos | Economía: precio, capacidad y velocidad | Entorno hace el modelo; Sistemas programa la conducción |
| Puntos del mapa | Sistemas: qué puntos necesita (ventas, retenes, apariciones) | Entorno los coloca con el nombre exacto del catálogo |
| Capítulos y logros | Economía: qué se pide y qué se premia | Sistemas los programa |

### Tareas por fase hasta el lanzamiento

| Fase | Andrés (Entorno) | Santiago (Economía) | Pablo (Sistemas) |
| --- | --- | --- | --- |
| 1. Bucle base | Un barrio, una cocina, 3 dulces, bicicleta y moto | Precios y tiempos iniciales, bocetos de la interfaz | Producción, carga, venta, guardado de datos |
| 2. Persecución | Policía Dental, patrullas, efectos de crema y confeti | Reglas de búsqueda, cuánto se pierde, daño y costo de las armas | Patrullas, estrellas, retenes, escondites, primeras armas |
| 3. Rutina diaria | Tienda del contrabandista, decoración del colegio | Lista de encargos, tabla de premios, pantallas de la rutina | Racha, encargos, dulce del día, producción en ausencia |
| 4. Publicación | Pulido del mapa, iluminación, música, arte del icono y miniaturas | Descripción, precios de gamepasses, pruebas con jugadores, lanzamiento | Corrección de errores, tutorial guiado, gamepasses |

### Reglas de trabajo

- **Un solo dueño por decisión.** Los otros dos opinan, pero el dueño del área decide.
- **Economía entrega números, no código.** Precios y tiempos viven en una hoja que Sistemas lee, para ajustar sin reprogramar.
- **Trabajo en el mismo lugar.** Usen la edición en equipo de Roblox Studio y un tablero de tareas con tres columnas: por hacer, en curso y hecho.
- **Una reunión corta por semana.** Cada uno dice qué terminó, qué sigue y qué lo frena.
- **Las ganancias se acuerdan antes.** Publiquen el juego desde un grupo de Roblox y dejen por escrito el porcentaje de cada uno antes de lanzar.

## Agentes: tres especialistas, un auditor y un integrador

Son cinco agentes: uno por integrante, que solo trabaja en su área, más un auditor que busca discrepancias y un integrador que une lo aprobado. Lo que evita los choques no son los agentes sino tres contratos compartidos que todos leen y que el auditor hace cumplir.

### Los tres contratos

Son la única fuente de verdad. Si algo no está en un contrato, no existe para los demás.

| Contrato | Dueño | Qué contiene | Ejemplo de fila |
| --- | --- | --- | --- |
| Tabla de datos | Economía | Cada dulce, arma, vehículo y mejora con su identificador y sus números | `Dulce_Arequipe`: nivel casero, valor 5, se abre en capítulo 3 |
| Catálogo de objetos | Entorno | Cada modelo, efecto, sonido y punto del mapa con su nombre exacto y su estado | `Vehiculo_Moto`: modelo listo, con punto `Carga` |
| Lista de eventos | Sistemas | Cada función y evento que el código ofrece o espera | `VentaRealizada(jugador, idDulce, cantidad)` |

La regla que los une: un mismo identificador, escrito igual, en los tres. Formato `Tipo_Nombre`, sin tildes ni espacios: `Dulce_Arequipe`, `Arma_PistolaCrema`, `Vehiculo_Moto`.

### Qué hace cada agente

| Agente | Trabaja para | Misión | Entrega | No puede |
| --- | --- | --- | --- | --- |
| Agente de Entorno | Andrés | Planear zonas del mapa, listas de modelos, nombres, puntos de anclaje y guía de estilo | Fichas de objetos y actualizaciones del catálogo | Inventar precios, reglas o código |
| Agente de Economía | Santiago | Calcular precios, tiempos, curvas de progresión, encargos y premios, y simular cuánto tarda cada capítulo | Filas de la tabla de datos y textos de pantallas | Crear identificadores sin avisar, ni tocar código o modelos |
| Agente de Sistemas | Pablo | Escribir y revisar el código de cada sistema | Scripts y actualizaciones de la lista de eventos | Escribir números fijos en el código: siempre los lee de la tabla de datos |
| Agente Auditor | Los tres | Comparar cada entrega contra los tres contratos y las reglas de contenido | Informe con veredicto: aprobado o lista de discrepancias | Corregir él mismo: solo señala, el dueño arregla |
| Agente Integrador | Los tres | Unir lo aprobado en la versión común y llevar el registro | Versión unificada, registro de cambios y resumen semanal | Unir algo que el auditor no aprobó, ni resolver un conflicto por su cuenta |

### El flujo de cada entrega

1. **Encargo.** El integrante le pide la tarea a su agente y le pasa los tres contratos vigentes.
2. **Entrega con nota.** El agente devuelve el trabajo y una nota de entrega con formato fijo.
3. **Auditoría.** El auditor revisa la entrega con su lista de control y da su veredicto.
4. **Corrección.** Si hay discrepancias, vuelven al dueño del área. Si la discrepancia está en una frontera, decide quien indica la tabla de fronteras.
5. **Integración.** El integrador une lo aprobado, actualiza el registro y avisa a los otros dos si cambió algún contrato.
6. **Firma humana.** El dueño del área prueba el cambio dentro del juego y lo da por hecho. Ningún agente cierra una tarea solo.

### Nota de entrega

Cada entrega, de cualquier agente, lleva estos cinco puntos:

- Qué se hizo, en una frase.
- Identificadores creados, cambiados o eliminados.
- Contratos que hay que actualizar y con qué filas.
- Cómo probarlo dentro del juego.
- Qué quedó pendiente o depende de otra área.

### Lista de control del auditor

- [ ] Todo identificador usado existe en la tabla de datos, en el catálogo y en el código, escrito igual.
- [ ] No hay objetos en el catálogo sin fila de datos, ni filas de datos sin objeto.
- [ ] El código no tiene precios, tiempos ni daños escritos a mano.
- [ ] Cada evento que el código usa está en la lista de eventos con los mismos parámetros.
- [ ] Cada capítulo se puede completar con los números actuales, y su logro pide algo que ya existe.
- [ ] Los textos de las pantallas coinciden con los nombres de la tabla de datos.
- [ ] La entrega cumple las reglas de contenido: sin nombres reales, sin polvos ni drogas, sin armas realistas.
- [ ] La nota de entrega está completa.

### Ritmo

- **En cada entrega:** auditoría e integración, el mismo día.
- **Cada semana:** el integrador entrega un resumen con lo unido, lo rechazado y los contratos que cambiaron. Los tres lo revisan en la reunión.
- **Al cerrar cada fase:** auditoría completa de los tres contratos, de principio a fin.

### Límites de los agentes

- Trabajan sobre texto: código, tablas, listas e informes. El agente de Entorno planea y verifica, pero el modelado y la construcción del mapa los hace la persona.
- Reducen los errores, no los eliminan. Por eso el auditor no corrige, el integrador no decide y la firma final siempre es humana.
- El auditor solo detecta lo que está en los contratos. Un contrato desactualizado es el fallo más probable de todo el sistema.

## Música y sonido

La banda sonora es música típica colombiana compuesta para el juego: los géneros no tienen dueño, pero cada canción y cada grabación comercial sí. Andrés es el dueño del sonido dentro de Entorno.

| Momento del juego | Género | Instrumentos | Sensación |
| --- | --- | --- | --- |
| Menú y fincas | Bambuco o pasillo instrumental | Tiple, guitarra, bandola | Calma, tierra, madrugada |
| Barrio y ventas | Parranda paisa | Guitarras, guacharaca, voces alegres | Fiesta de cuadra |
| Carretera y entregas | Carrilera | Guitarras y requinto | Viaje, camino largo |
| Persecución | Banda papayera acelerada | Trompetas, redoblante, platillos | Caos cómico |
| Internado Sin Azúcar | Pasillo lento | Una sola guitarra desafinada | Tristeza de mentiras |
| Diciembre | Parranda decembrina | Todo lo anterior más maracas | Temporada de natilla y buñuelos |

### De dónde sale la música

| Fuente | Cómo | Cuidado |
| --- | --- | --- |
| Composición original | Un músico o trío local graba temas propios en esos géneros | Dejar por escrito que el juego puede usarlos |
| Tienda de creadores de Roblox | Buscar pistas ya licenciadas dentro de Studio | Solo sirven dentro de Roblox |
| Obras tradicionales antiguas | Grabar una versión propia de una obra en dominio público | Verificar cada obra; la grabación de otro artista sigue protegida |
| Música generada con IA | Pedir el género, nunca un artista o canción concretos | Revisar que la herramienta permita uso comercial |

### Lo que no se puede

- Subir canciones bajadas de YouTube, Spotify o cualquier grabación comercial, aunque sean viejas o muy conocidas.
- Usar la canción de una serie o versiones que la imiten.
- Hacer una versión propia de una canción con autor vigente sin su licencia.

### Idea de juego: la radio del vehículo

Cada vehículo trae radio con emisoras inventadas, como Radio Panela o La Voz del Trapiche, y el jugador cambia de género mientras maneja. Las emisoras nuevas se desbloquean con fama y son otro coleccionable.

## Herramientas y repositorio

El proyecto vive en git como archivos y se ve en Roblox Studio con Rojo, que sincroniza la carpeta del repositorio con Studio en vivo. No hay emulador de Roblox aparte: la prueba real siempre es el modo de juego de Studio.

### Qué va en git y qué no

| Contenido | Dónde vive | Quién lo cambia |
| --- | --- | --- |
| Código Luau | Repositorio, carpeta `src/` | Sistemas |
| Tabla de datos | Repositorio, `src/shared/Datos/`, como módulos generados desde la hoja | Economía |
| Contratos y documentos | Repositorio, carpeta `contratos/` | Cada dueño el suyo |
| Modelos sueltos: dulces, armas, vehículos | Repositorio, carpeta `assets/`, como archivos de modelo | Entorno |
| Mapa completo | Lugar de Roblox con edición en equipo | Entorno |

El mapa se queda en Studio porque es un archivo binario que git no puede combinar. Rojo se configura para sincronizar solo las carpetas de código y datos, sin tocar el mapa.

### Herramientas por integrante

| Quién | Herramientas | Para qué |
| --- | --- | --- |
| Los tres | Git y GitHub, Roblox Studio, [Rokit](https://github.com/rojo-rbx/rokit), plugin de Rojo | Mismo repositorio y mismas versiones de herramientas en los tres computadores |
| Pablo (Sistemas) | VS Code con Luau LSP, [Rojo](https://create.roblox.com/docs/projects/external-tools), Wally, Selene, StyLua | Escribir código, sincronizarlo, instalar paquetes, revisar errores y dar formato |
| Andrés (Entorno) | Roblox Studio, Blender | Construir el mapa y modelar objetos |
| Santiago (Economía) | Hoja de cálculo, Figma o Canva, tablero de GitHub Projects | Números, pantallas y seguimiento de tareas |

### MCP para los agentes

| MCP | Lo usan | Para qué |
| --- | --- | --- |
| [Roblox Studio MCP](https://create.roblox.com/docs/studio/mcp), integrado en Studio | Agentes de Sistemas y Entorno, Auditor | Leer y escribir scripts, recorrer el árbol de objetos, ejecutar pruebas de juego y capturar la vista |
| GitHub | Auditor e Integrador | Leer cada solicitud de cambio, comentar discrepancias y unir ramas |
| Hoja de cálculo, por ejemplo Google Sheets | Agente de Economía | Leer la tabla de datos y proponer filas |
| Blender, de la comunidad y opcional | Agente de Entorno | Ayuda con modelos; pruébenlo antes de depender de él |

El MCP de Studio es el que le permite al auditor comprobar el catálogo contra lo que de verdad existe en el juego, nombre por nombre. Como un agente con ese acceso puede modificar el lugar, conéctenlo a una copia de pruebas y no al lugar publicado.

### Cómo ver el proyecto en Roblox

1. Instala Rokit y, dentro de la carpeta del repositorio, ejecuta `rokit install`. Eso baja las versiones fijadas en `rokit.toml`.
2. Ejecuta `wally install` para bajar los paquetes.
3. Ejecuta `rojo serve`. Queda un servidor local leyendo tus archivos.
4. Abre en Studio el lugar del equipo y, en el plugin de Rojo, pulsa conectar. El código del repositorio aparece dentro de Studio y se actualiza al guardar.
5. Pulsa jugar para probar. Para probar varios jugadores, usa la prueba con servidor local y 2 o 3 jugadores.
6. Para generar un archivo de lugar desde el repositorio, sin abrir el del equipo, ejecuta `rojo build -o ElPatronDelDulce.rbxl`. Sirve como comprobación rápida de que todo arma bien.

### Estructura del repositorio

```
el-patron-del-dulce/
  default.project.json   mapa de carpetas a servicios de Roblox (Rojo)
  rokit.toml             versiones fijas de las herramientas
  wally.toml             paquetes
  selene.toml            reglas del revisor de código
  stylua.toml            formato del código
  src/
    server/              código del servidor: economía, policía, guardado
    client/              código del jugador: interfaz, controles
    shared/
      Datos/             tabla de datos como módulos
      Eventos/           eventos entre servidor y jugador
  assets/                modelos sueltos
  contratos/
    tabla-de-datos.md
    catalogo-de-objetos.md
    lista-de-eventos.md
  auditorias/            informes del auditor
  .github/workflows/     verificación automática
```

### Cómo encajan los agentes en git

- **Una rama por tarea**, con el área como prefijo: `entorno/`, `economia/`, `sistemas/`.
- **La solicitud de cambio lleva la nota de entrega** como descripción.
- **Verificación automática en cada solicitud:** Selene, StyLua en modo comprobación y `rojo build`. Si falla, el auditor ni la revisa.
- **El auditor comenta en la solicitud** con su veredicto y guarda el informe en `auditorias/`.
- **El integrador une a la rama principal** solo con el aprobado del auditor y la firma del dueño del área.
- **Nadie escribe directo en la rama principal.** Se protege desde la configuración de GitHub.
- **Publicar en Roblox lo hace una persona** desde Studio, al cerrar cada fase.

Fuentes: [herramientas externas, documentación de Roblox](https://create.roblox.com/docs/projects/external-tools) y [servidor MCP de Roblox Studio](https://create.roblox.com/docs/studio/mcp).

## Arranque del repositorio: tareas de Pablo

Pablo crea el repositorio y lo deja funcionando antes de invitar a Andrés y a Santiago. Son 9 pasos y terminan cuando los otros dos pueden clonar, conectar Rojo y ver el código dentro de Studio.

### Paso 1. Instalar lo básico

Instala Git, VS Code, Roblox Studio y [Rokit](https://github.com/rojo-rbx/rokit). En VS Code agrega las extensiones Luau LSP, Rojo, Selene y StyLua.

### Paso 2. Crear el repositorio y las herramientas

```bash
mkdir el-patron-del-dulce
cd el-patron-del-dulce
git init -b main
rokit init
rokit add rojo-rbx/rojo
rokit add UpliftGames/wally
rokit add Kampfkarren/selene
rokit add JohnnyMorganz/StyLua
rojo init
wally init
```

`rokit add` deja las versiones fijadas en `rokit.toml`. Ese archivo es el que garantiza que los tres usen lo mismo.

### Paso 3. Crear las carpetas

```bash
mkdir -p src/server src/client src/shared/Datos src/shared/Eventos
mkdir -p assets contratos auditorias .github/workflows
```

Git no guarda carpetas vacías: pon un archivo `.gitkeep` en `assets` y en `auditorias`.

### Paso 4. Reemplazar el archivo de Rojo

El archivo que genera `rojo init` también administra el mapa y la iluminación, y eso pisaría el trabajo de Andrés. Reemplaza todo `default.project.json` por esta versión, que solo sincroniza código y datos:

```json
{
  "name": "el-patron-del-dulce",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "Shared": { "$path": "src/shared" }
    },
    "ServerScriptService": {
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "StarterPlayerScripts": {
        "Client": { "$path": "src/client" }
      }
    }
  }
}
```

Cuando instales el primer paquete con `wally install`, agrega dentro de `ReplicatedStorage` la línea `"Packages": { "$path": "Packages" }`.

### Paso 5. Archivos de configuración

`selene.toml`:

```toml
std = "roblox"
```

`stylua.toml`:

```toml
column_width = 100
indent_type = "Tabs"
```

`.gitignore`:

```
Packages/
sourcemap.json
*.rbxl
*.rbxlx
*.rbxl.lock
*.rbxlx.lock
```

### Paso 6. Los tres contratos y las plantillas

Crea los contratos solo con sus encabezados; cada dueño los llena después.

`contratos/tabla-de-datos.md`:

```markdown
# Tabla de datos (dueño: Santiago)
| Identificador | Tipo | Nivel | Valor | Tiempo | Se abre en |
| --- | --- | --- | --- | --- | --- |
```

`contratos/catalogo-de-objetos.md`:

```markdown
# Catálogo de objetos (dueño: Andrés)
| Identificador | Clase | Ubicación en el juego | Puntos de anclaje | Estado |
| --- | --- | --- | --- | --- |
```

`contratos/lista-de-eventos.md`:

```markdown
# Lista de eventos (dueño: Pablo)
| Nombre | Dirección | Parámetros | Qué hace |
| --- | --- | --- | --- |
```

`.github/pull_request_template.md`, para que cada solicitud de cambio traiga la nota de entrega:

```markdown
## Nota de entrega
- Qué se hizo:
- Identificadores creados, cambiados o eliminados:
- Contratos que hay que actualizar:
- Cómo probarlo dentro del juego:
- Qué quedó pendiente:
```

`.github/CODEOWNERS`, con los usuarios reales de GitHub. La última regla que coincide es la que manda:

```
/src/                               @USUARIO_PABLO
/contratos/lista-de-eventos.md      @USUARIO_PABLO
/src/shared/Datos/                  @USUARIO_SANTIAGO
/contratos/tabla-de-datos.md        @USUARIO_SANTIAGO
/assets/                            @USUARIO_ANDRES
/contratos/catalogo-de-objetos.md   @USUARIO_ANDRES
```

### Paso 7. Verificación automática

`.github/workflows/verificar.yml`:

```yaml
name: Verificar
on:
  pull_request:
  push:
    branches: [main]
jobs:
  verificar:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: CompeyDev/setup-rokit@v0.1.2
      - run: selene src
      - run: stylua --check src
      - run: rojo build -o build.rbxl
```

Antes de confiar en él, confirma en GitHub la versión vigente de la acción `setup-rokit` y que la primera ejecución pase en verde.

### Paso 8. Primer commit y GitHub

```bash
git add .
git commit -m "Estructura inicial del proyecto"
git remote add origin https://github.com/ORGANIZACION/el-patron-del-dulce.git
git push -u origin main
```

El repositorio debe existir en GitHub antes del push: créalo vacío y privado, dentro de una organización del equipo. Después del push, en su página:

- [ ] Confirmar que el repositorio quedó privado.
- [ ] Invitar a Andrés y a Santiago como colaboradores.
- [ ] Proteger la rama `main`: exigir solicitud de cambio, una aprobación, revisión del dueño según CODEOWNERS y que pase la verificación.
- [ ] Crear el tablero de tareas con tres columnas: por hacer, en curso y hecho.

La protección de ramas en repositorios privados depende del plan de GitHub. Si el plan gratuito no la permite, revisen el paquete de GitHub para estudiantes; mientras tanto, la regla se cumple por acuerdo.

### Paso 9. Conectar con Roblox

1. Crea en Roblox el lugar de pruebas del equipo y activa la edición en equipo. Quién es dueño del grupo lo deciden los tres.
2. Instala el plugin de Rojo en Studio.
3. En la carpeta del repositorio ejecuta `rojo serve`.
4. En Studio abre el plugin de Rojo y pulsa conectar.
5. Crea `src/server/Inicio.server.luau` con `print("El Patrón del Dulce: servidor listo")`, pulsa jugar y confirma que el mensaje sale en la ventana de salida.
6. Activa el MCP de Studio desde el Assistant, en la gestión de servidores MCP, sobre este lugar de pruebas.

### Cómo saber que terminó

- [ ] Andrés y Santiago clonaron y `rokit install` les funcionó sin errores.
- [ ] Los tres ven el mensaje de prueba en Studio al conectar Rojo.
- [ ] Una solicitud de cambio de prueba muestra la plantilla, corre la verificación y pide la aprobación del dueño correcto.
- [ ] Los tres contratos existen con sus encabezados.

## Arranque de Andrés: Entorno

Andrés empieza cuando Pablo terminó su arranque. Son 8 pasos y terminan con el primer dulce modelado, importado y registrado en el catálogo.

### Paso 1. Instalar lo básico

Instala Roblox Studio, Blender, Git y Rokit. Si prefieres no usar la terminal, instala GitHub Desktop.

### Paso 2. Clonar el repositorio

```bash
git clone https://github.com/ORGANIZACION/el-patron-del-dulce.git
cd el-patron-del-dulce
rokit install
```

### Paso 3. Entrar al lugar del equipo

Acepta la invitación al grupo de Roblox y abre el lugar de pruebas en Studio con edición en equipo. Ahí construyes el mapa directamente; no necesitas ejecutar Rojo.

### Paso 4. Crear las carpetas del juego

Dentro de Studio crea esta estructura. Rojo no la toca, así que es tuya:

```
ReplicatedStorage
  Assets
    Dulces
    Armas
    Vehiculos
    Personajes
    Utileria
Workspace
  Mapa
  Puntos
    Ventas
    Apariciones
    Retenes
    Escondites
```

### Paso 5. Fijar la escala y el estilo

1. Modela en Blender un cubo de prueba, expórtalo en FBX e impórtalo en Studio con el importador 3D.
2. Compáralo con un personaje de Roblox y ajusta la escala de exportación hasta que coincida. Anota ese valor y úsalo siempre.
3. Escribe en `contratos/guia-de-estilo.md` la paleta de colores, la escala y las reglas: pocos polígonos, colores planos, formas redondeadas.

### Paso 6. Primer modelo completo

1. Modela el bombón en Blender.
2. Expórtalo como `Dulce_Bombon.fbx`.
3. Impórtalo en Studio y déjalo en `ReplicatedStorage.Assets.Dulces` con el nombre exacto `Dulce_Bombon`.
4. Guárdalo también como archivo de modelo en la carpeta `assets/` del repositorio, como respaldo.

### Paso 7. Registrar y entregar

```bash
git checkout -b entorno/dulce-bombon
```

1. Agrega la fila del bombón en `contratos/catalogo-de-objetos.md`.
2. Sube la rama y abre la solicitud de cambio llenando la nota de entrega.
3. Espera el veredicto del auditor y la unión.

```bash
git add .
git commit -m "Agrega Dulce_Bombon al catálogo"
git push -u origin entorno/dulce-bombon
```

### Paso 8. Primera entrega completa

- [ ] Seis dulces: bombón, chicle, gomita, arequipe, panelita y bocadillo.
- [ ] Bicicleta y moto, cada una con un punto llamado `Carga`.
- [ ] Barrio en bloques: el colegio, 6 tiendas, la cocina clandestina y dos carreteras.
- [ ] Los puntos que pida Pablo, dentro de `Workspace.Puntos`, con el nombre exacto de la lista.
- [ ] Cada pieza con su fila en el catálogo.

### Reglas de Andrés

- El nombre en Studio, en el archivo y en el catálogo es el mismo, letra por letra.
- No cambies el nombre de algo ya entregado sin avisar: el código de Pablo lo busca por ese nombre.
- No pongas scripts dentro de los modelos; todo el código va por el repositorio.
- Usa el agente de Entorno para listas de piezas, medidas y revisión de nombres, no para el arte final.

## Arranque de Santiago: Economía

Santiago también empieza cuando Pablo terminó su arranque. Son 8 pasos y terminan con la tabla de datos inicial unida al repositorio.

### Paso 1. Instalar lo básico

Crea tu cuenta de GitHub e instala GitHub Desktop y Roblox Studio, que usarás para probar el juego. Ten a mano una hoja de cálculo y Figma o Canva.

### Paso 2. Clonar el repositorio

En GitHub Desktop elige clonar repositorio y selecciona `el-patron-del-dulce`. No necesitas la terminal.

### Paso 3. Crear la hoja de datos

Crea una hoja llamada "Tabla de datos" y compártela con Pablo y Andrés en modo lectura. Lleva una pestaña por tipo:

| Pestaña | Columnas |
| --- | --- |
| Dulces | Identificador, nivel, valor de venta, tiempo de producción, capítulo en que se abre |
| Armas | Identificador, efecto, duración, dulces que gasta por disparo, capítulo |
| Vehículos | Identificador, precio, capacidad, velocidad, capítulo |
| Mejoras | Identificador, nivel, precio, qué mejora y cuánto |
| Tiendas | Identificador, dulces que compra, demanda base |
| Encargos | Identificador, texto, meta, premio |

### Paso 4. Llenar los valores iniciales

Empieza con los 6 dulces, 2 armas, 2 vehículos y 6 tiendas del lanzamiento. Usa los valores de la sección de economía como punto de partida. Los identificadores siguen el formato `Tipo_Nombre` y deben coincidir con los de Andrés.

### Paso 5. Simular el ritmo

Agrega una pestaña "Simulación" que calcule cuántos pesos gana un jugador por minuto y cuánto tarda en comprar cada mejora. Las metas de partida, para ajustar con pruebas:

| Capítulo | Tiempo de juego para terminarlo |
| --- | --- |
| 1. El recreo | 5 minutos |
| 2. La esquina | 15 minutos |
| 3. La cocina de la abuela | 30 minutos |
| 4. La ruta | 60 minutos |

### Paso 6. Pasar la hoja al repositorio

1. En GitHub Desktop crea la rama `economia/tabla-inicial`.
2. Copia las filas a `contratos/tabla-de-datos.md`.
3. Pídele al agente de Economía que genere los módulos de `src/shared/Datos/` a partir de la hoja.
4. Sube la rama y abre la solicitud de cambio con la nota de entrega.

### Paso 7. Pantallas y textos

- [ ] Bocetos de 6 pantallas: mejoras, inventario, estrellas, encargos del día, racha y capítulo actual.
- [ ] Imágenes exportadas a `contratos/pantallas/`, una por pantalla.
- [ ] Textos del tutorial y diálogos de Doña Melcocha y Don Ábaco en `contratos/textos.md`.

### Paso 8. Tablero y pruebas

- [ ] Cargar en el tablero las tareas de la fase 1 de los tres.
- [ ] Preparar la prueba de la fase 1: 5 personas que no conozcan el juego, midiendo cuánto tardan en su primera entrega. La meta es menos de 2 minutos.
- [ ] Convocar la reunión semanal y llevar el resumen del integrador.

### Reglas de Santiago

- La hoja es la única fuente de los números. Si un valor cambia, cambia primero ahí.
- No crees un identificador nuevo sin avisar a Andrés y a Pablo: necesita modelo y código.
- Cambia pocos valores a la vez y anota el motivo, para saber qué ajuste funcionó.
- Usa el agente de Economía para proponer y simular; la decisión final sale de jugarlo.

## Primera entrega de Pablo: bucle base

Después del arranque, Pablo construye la fase 1 en 6 solicitudes de cambio, en este orden, porque cada una se apoya en la anterior.

| # | Rama | Qué entrega | Está lista cuando |
| --- | --- | --- | --- |
| 1 | `sistemas/lector-datos` | Módulo que lee la tabla de datos y la ofrece al resto del código | Ningún otro script tiene números escritos a mano |
| 2 | `sistemas/produccion` | Las cocinas fabrican el dulce elegido con su tiempo | Un bombón aparece en la cocina al cumplirse el tiempo |
| 3 | `sistemas/carga` | Inventario del jugador y carga en el vehículo | La carga se ve en el punto `Carga` de la moto |
| 4 | `sistemas/venta` | Venta en tiendas según la demanda | Vender en un punto de `Ventas` suma pesos |
| 5 | `sistemas/mejoras` | Compra de mejoras de cocina y vehículo | Una mejora comprada cambia la producción |
| 6 | `sistemas/guardado` | Guardado con ProfileStore | Salir y volver a entrar conserva pesos, dulces y mejoras |

### Reglas de Pablo

- Toda la lógica de dinero y premios corre en el servidor; el cliente solo pide y muestra.
- Cada evento nuevo se anota en `contratos/lista-de-eventos.md` en la misma solicitud de cambio.
- Solo Pablo sincroniza con Rojo el código de la rama principal hacia el lugar del equipo. Para probar una rama, cada uno usa una copia local del lugar.
- Pídele a Andrés los puntos del mapa por escrito, con nombre exacto, antes de programar contra ellos.

## Inventario de producción

Todo lo que hay que fabricar cae en seis formas de hacerlo, y cada una tiene un dueño. La lista cubre las fases 1 a 4, hasta el lanzamiento; lo demás se suma después con la misma lógica.

| Forma de hacerlo | Qué se hace así | Quién |
| --- | --- | --- |
| Modelar en Blender | Objetos con forma propia: dulces, armas, vehículos, accesorios de personajes | Andrés |
| Construir en Roblox Studio | Mapa, edificios, iluminación, partículas, animaciones | Andrés |
| Programar desde cero | Las reglas propias del juego | Pablo |
| Usar piezas ya hechas | Guardado de datos, rutas de la policía, insignias, compras | Pablo |
| Diseñar fuera del motor | Tabla de datos, pantallas, icono, textos | Santiago |
| Grabar o licenciar | Música y efectos de sonido | Andrés, con músicos externos |

### Modelar en Blender

| Grupo | Piezas para el lanzamiento | Después |
| --- | --- | --- |
| Dulces | Bombón, chicle, gomita, arequipe, panelita, bocadillo | Los otros 24 del recetario |
| Armas | Cauchera de gomitas, pistola de crema | Las otras 6 |
| Vehículos | Bicicleta, moto, patrulla dental | Camioneta, chiva, avioneta |
| Personajes | Accesorios de Doña Melcocha, Don Ábaco, Maestro Tuerca y un agente de la Policía Dental | Los otros 8 personajes |
| Utilería | Olla, estufa, caja de carga, mostrador, retén, cepillo gigante | Piezas de fincas y del internado |

Reglas de modelado: pocos polígonos, colores planos y formas redondeadas. Cada archivo se exporta en formato FBX y se nombra con su identificador del catálogo, por ejemplo `Vehiculo_Moto`.

### Construir en Roblox Studio

- **Mapa de lanzamiento:** un barrio en ladera con el colegio, 6 tiendas, la cocina clandestina y dos carreteras con retenes.
- **Puntos del juego:** ventas, apariciones, retenes y escondites, colocados con el nombre exacto que pide Sistemas.
- **Partículas:** crema, confeti, espuma y humo de colores para armas y averías.
- **Animaciones:** cocinar, cargar cajas, lanzar con cauchera, quedar empalagado.
- **Iluminación:** ciclo de día y noche, con ambiente cálido de tarde.

### Programar desde cero

| Fase | Sistemas propios |
| --- | --- |
| 1. Bucle base | Producción en cocinas, inventario y carga, venta con demanda por tienda, compra de mejoras, lectura de la tabla de datos |
| 2. Persecución | Estrellas de búsqueda, comportamiento de patrullas y retenes, confiscación de carga, armas con munición de dulces, escondites |
| 3. Rutina diaria | Racha con comodín, tres encargos, dulce del día, producción en ausencia, hora del recreo |
| 4. Publicación | Capítulos y logros, tutorial guiado, pantallas funcionando, validación en el servidor contra trampas |

### Piezas ya hechas, que no se programan

- **Guardado de datos:** un paquete probado como ProfileStore, instalado con Wally, en vez de escribir el guardado a mano.
- **Rutas de la policía:** el servicio de búsqueda de caminos de Roblox.
- **Conducción:** los asientos de vehículo y las restricciones físicas del motor.
- **Insignias y compras:** los servicios de insignias y de mercado de Roblox.
- **Efectos de sonido comunes:** la tienda de creadores.

### Diseñar fuera del motor

- **Tabla de datos inicial:** 6 dulces, 2 armas, 3 vehículos, mejoras de cocina y precios de las 6 tiendas.
- **Pantallas:** tienda de mejoras, inventario, estrellas, encargos del día, racha, capítulo actual.
- **Textos:** tutorial, diálogos de Doña Melcocha y Don Ábaco, descripción del juego.
- **Imagen del juego:** icono y 3 miniaturas.

### Grabar o licenciar

- **Música original para el lanzamiento:** el tema insignia en parranda y tres ambientes: barrio, carretera y persecución.
- **Después:** fincas, internado, diciembre y las emisoras de radio.
- **Efectos propios:** disparo de crema, explosión de confeti, sirena dental, caja registradora.

### Dónde ayudan los agentes y los MCP

| Tarea | Agente | MCP |
| --- | --- | --- |
| Escribir y revisar scripts | Agente de Sistemas | Roblox Studio y GitHub |
| Ejecutar pruebas de juego y leer errores | Agente de Sistemas | Roblox Studio |
| Comprobar que cada modelo y punto del mapa existe con su nombre | Auditor | Roblox Studio |
| Generar los módulos de datos desde la hoja | Agente de Economía | Hoja de cálculo y GitHub |
| Listas de modelos, medidas y guía de estilo | Agente de Entorno | Ninguno; Blender opcional |
| Revisar y unir solicitudes de cambio | Auditor e Integrador | GitHub |

Modelar, construir el mapa, componer y decidir los números siguen siendo trabajo de las personas.

## Delegación y aprobación

Los agentes hacen el trabajo y las personas aprueban: ningún cambio llega al juego sin la firma del dueño del área. Cuánto se delega depende de la tarea.

| Tarea | Cuánto se delega | Qué hace el agente | Qué aprueba la persona | Quién aprueba |
| --- | --- | --- | --- | --- |
| Código de los sistemas | Casi todo | Escribe, prueba en Studio y corrige | Que funcione al jugarlo | Pablo |
| Tabla de datos y balance | Casi todo | Propone números y simula la progresión | Que el ritmo se sienta bien | Santiago |
| Textos, diálogos y encargos | Casi todo | Redacta | Tono y humor | Santiago |
| Auditoría e integración | Casi todo | Compara contra los contratos y une ramas | La unión a la rama principal | El dueño del área |
| Pantallas e interfaz | Buena parte | Arma las pantallas en código | Diseño y claridad | Santiago |
| Mapa | Una parte | Bloquea zonas y coloca puntos | Forma y estilo final | Andrés |
| Música | Una parte | Genera o propone pistas | Elección y licencia | Andrés |
| Modelos 3D | Poco | Utilería simple | Vehículos, personajes y armas se hacen a mano | Andrés |
| Publicar y cobrar | Nada | No participa | Todo | Los tres |

### Reglas de aprobación

- **Entregas pequeñas.** Se aprueba un sistema o una pieza a la vez, nunca todo al final.
- **Aprobar es jugarlo.** Quien aprueba abre Studio y prueba el cambio; leer el informe del agente no cuenta.
- **Rama principal protegida.** GitHub exige la firma del dueño del área antes de unir.
- **Copia de pruebas.** Los agentes trabajan sobre una copia del lugar, nunca sobre el publicado.
- **Publicar es de personas.** Ningún agente tiene permiso de publicar ni de mover Robux.
- **Rechazar es normal.** Una entrega rechazada vuelve al agente con el motivo escrito, y ese motivo se agrega a sus instrucciones.

El arte es donde menos conviene delegar: lo generado tiende a verse genérico, y el estilo visual es lo que distingue al juego.

## Plan de construcción

La primera versión publicable son solo los capítulos 1 a 4: producir, mover, vender y huir. Si ese bucle no divierte solo, ningún sistema diario lo arregla.

| Fase | Qué incluye | Está lista cuando |
| --- | --- | --- |
| 1. Bucle base | Mapa de un barrio, una cocina, 3 dulces, bicicleta y moto, venta en tiendas, guardado de datos | Un jugador nuevo completa una entrega en menos de 2 minutos sin ayuda |
| 2. Persecución | Policía Dental, estrellas de búsqueda, retenes, escondites | Perder la carga se siente justo y dan ganas de reintentar |
| 3. Rutina diaria | Racha, tres encargos, dulce del día, producción en ausencia | Los probadores vuelven al día siguiente sin que se lo pidas |
| 4. Publicación | Capítulos 1 a 4, tutorial, icono y miniaturas | Primer lanzamiento público |
| 5. Bandas | Bandas, bodegas, territorios, asalto de rutas | Los servidores se llenan de grupos de amigos |
| 6. Final de campaña | Mansión, avioneta, Comandante Muelas, renacimiento | Hay jugadores con más de un renacimiento |
| 7. Temporadas | Pase, tienda rotativa, dulces legendarios | Cada temporada trae de vuelta a jugadores antiguos |

### Qué medir desde el primer día

- **Retención al día 1 y al día 7:** cuántos vuelven. Es la medida directa de si la rutina diaria funciona.
- **Duración de sesión:** si queda muy por debajo de 10 minutos, el bucle base aburre.
- **Capítulo de abandono:** en qué capítulo se va la mayoría; ahí está el muro de dificultad o de precio.

### Preguntas abiertas

- [ ] ¿Cada uno quedó en el área que mejor maneja? Si no, intercambiar nombres.
- [ ] ¿La ciudad tendrá nombre propio? Hace falta uno inventado.
- [ ] ¿El asalto de rutas entra en el lanzamiento o después?
