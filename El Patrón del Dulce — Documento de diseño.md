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

## Mundo en anillos

El mapa es un solo mundo abierto organizado en 5 anillos alrededor del colegio, y cada capítulo abre una parte del anillo siguiente. El jugador siempre ve desde donde está la zona que todavía no puede pisar, y eso es lo que lo empuja a seguir.

&#91;embedded content: mapa en anillos · centro y 5 anillos\]

El jugador empieza en el colegio y avanza hacia afuera: cada anillo queda más lejos, es más peligroso y paga mejor.

| Anillo | Zonas | Se abre en | Qué lo cierra antes | Peligro base | Por qué se vuelve después |
| --- | --- | --- | --- | --- | --- |
| Centro | Colegio y casa de la familia | Capítulo 1 | Nada: es el inicio | Solo el Coordinador | La hora del recreo, cada hora |
| 1. El barrio | 6 tiendas, cocina clandestina | Capítulos 2 y 3 | El portón del colegio | Sin policía | Ingreso pasivo de tiendas y dulce del día |
| 2. Las rutas | Dos carreteras, taller, bodega | Capítulos 4 y 5 | Retenes cerrados | 1 a 3 estrellas | Entregas grandes y mejoras de vehículo |
| 3. Los territorios | Tres barrios rivales y la guarida del chicle | Capítulo 6 | Barricadas de la Banda del Chicle | 2 a 4 estrellas y rivales | Guerra de territorios del fin de semana |
| 4. El campo | Fincas, pista y hangar | Capítulos 7 y 8 | Un derrumbe en la carretera | Inspecciones y asaltos | Cosecha diaria de cada finca |
| 5. El borde | Internado Sin Azúcar y salida a otras ciudades | Capítulos 8 y 9 | Solo se llega por aire o capturado | 5 estrellas | Fugas, exportación y una ciudad nueva por renacimiento |

### Reglas del mundo

- **Cada capítulo abre una tajada, no el anillo entero.** El capítulo 2 abre tres tiendas y el 3 las otras tres con la cocina, para que el desbloqueo se sienta varias veces.
- **Las barreras son físicas y se ven caer.** El portón se abre, el retén se levanta, el derrumbe se despeja con dinamita de piñata. Abrir una zona es una escena, no un mensaje.
- **Un punto alto visible desde todo el mapa.** La torre del colegio sirve para orientarse y recuerda de dónde salió el jugador.
- **La distancia pide mejores vehículos.** Cada anillo queda más lejos del centro, así que la bicicleta deja de alcanzar y la moto se vuelve necesaria.
- **Ningún anillo se abandona.** Cada uno conserva un motivo diario para volver, que es la última columna de la tabla.
- **Las siluetas adelantan lo que viene.** Las fincas se ven en la montaña desde el barrio y el internado se ve en el borde, con sus luces encendidas.

## Los primeros 10 minutos

El jugador nuevo decide en 10 minutos si se queda, así que ese tramo está diseñado minuto a minuto: un premio cada 60 a 90 segundos y un susto antes del minuto 3.

| Minuto | Qué pasa | Qué siente el jugador |
| --- | --- | --- |
| 0:00 | El Alcalde Apio prohíbe el azúcar por el altavoz del colegio, en 20 segundos | Curiosidad y ganas de llevarle la contraria |
| 0:30 | Doña Melcocha le pasa 5 bombones a escondidas | Complicidad |
| 1:00 | Primera venta a un niño: suenan monedas y el número salta | Primer premio |
| 2:00 | Aparece el Coordinador; hay que esconderse detrás de un muro | Primer susto |
| 3:00 | Recibe la cauchera y aturde al Coordinador | Poder |
| 5:00 | Primera compra: un morral más grande | Progreso visible |
| 7:00 | Suena la campana: primera hora del recreo, con ventas al doble | Euforia |
| 9:00 | Logro "Primer bombón": recibe la bicicleta, el portón se abre y se ve el barrio entero | Ganas de más |

La primera hora del recreo se dispara a propósito para todo jugador nuevo en el minuto 7, sin esperar a la hora en punto.

## Curva de dificultad

La presión sube en olas: después de cada capítulo duro viene uno que le da poder al jugador. Los tiempos son metas de partida para ajustar con pruebas.

| Capítulo | Amenaza nueva | Presión, de 1 a 5 | Tiempo de juego acumulado | Qué puede perder | El respiro que sigue |
| --- | --- | --- | --- | --- | --- |
| 1. El recreo | El Coordinador | 1 | 10 minutos | Unos pocos dulces | Bicicleta y un barrio sin policía |
| 2. La esquina | Solo las distancias | 1 | 25 minutos | Nada | Ingreso pasivo de las tiendas |
| 3. La cocina de la abuela | Administrar tiempos de producción | 2 | 55 minutos | Nada | La moto |
| 4. La ruta | Policía Dental y retenes | 3 | 2 horas | La carga del viaje | Escondites y pistola de crema |
| 5. La banda | Más carga atrae más búsqueda | 3 | 4 horas | La carga del viaje | Repartidores que trabajan solos |
| 6. La guerra del azúcar | Bandas rivales y primera jefa | 4 | 7 horas | Carga y territorio | Ingreso de los territorios |
| 7. La finca | Inspecciones y asaltos | 3 | 11 horas | La cosecha del día | La mansión: capítulo para disfrutar |
| 8. El puente aéreo | Rutas largas sin escondites | 4 | 16 horas | Carga de exportación | Dulces legendarios |
| 9. El más buscado | Cinco estrellas, jefe final e internado | 5 | 22 horas | Minutos en el internado | El renacimiento |
| 10. La leyenda | La campaña de nuevo, más rápida | 2 y sube | Sin límite | Lo mismo de antes | Multiplicador permanente |

### Reglas de dificultad

- **La policía responde a lo que haces, no a tu nivel.** Salen más agentes según las estrellas y el valor de la carga, así que el jugador elige cuánto riesgo toma.
- **La pérdida tiene techo.** Solo se arriesga la carga del viaje; el dinero guardado, las mejoras y las fincas nunca se pierden.
- **Fallar es rápido.** Entre perder la carga y volver a manejar pasan menos de 15 segundos.
- **Ayuda silenciosa.** Solo en los capítulos 1 a 3: tras 3 entregas perdidas seguidas, el siguiente viaje tiene un 20 % menos de patrullas. Del capítulo 4 en adelante la dificultad no afloja.
- **El reto extra es opcional.** La "ruta peligrosa" paga un 50 % más para quien quiera dificultad sin obligar al resto.

## Emociones y recompensas

Cada sistema existe para provocar una emoción concreta, y el juego nunca deja al jugador a más de 5 minutos de algún premio. El enganche viene de la tensión, la sorpresa y el progreso, no de trucos de pago.

| Emoción | Cuándo ocurre | Cómo se provoca | Señal en pantalla y sonido |
| --- | --- | --- | --- |
| Adrenalina | Persecución con carga grande | La carga vale más cuanto más lejos va; las patrullas se acercan de a poco | La papayera acelera con cada estrella, la sirena crece y los bordes de la pantalla laten |
| Alivio y triunfo | Llegar al escondite o a la tienda | Corte seco de la tensión | Silencio de un segundo, caja registradora y letrero de "entrega perfecta" |
| Sorpresa | En cualquier venta o producción | Premios poco frecuentes que no se pueden predecir | Destello dorado y un sonido que solo suena en esos casos |
| Anticipación | Entre sesiones | Cosas que se llenan o rotan con el tiempo | Relojes visibles en bodega, fincas, tienda y racha |
| Progreso | Todo el tiempo | Siempre hay una barra hacia el próximo desbloqueo | Barra fija en pantalla con el premio dibujado al final |
| Curiosidad | Al mirar el mapa o el recetario | Zonas a la vista pero cerradas, recetas en silueta | Siluetas oscuras con un signo de pregunta |
| Orgullo | Al mostrar lo logrado | Mansión visitable, títulos y tablas | El título sobre el nombre y titulares de Lola Paleta |
| Pertenencia | Jugando en banda | Metas que solo se logran entre varios | Colores de banda y bono de convoy |

### Ritmo de premios

| Cada cuánto | Tipo de premio | Ejemplo |
| --- | --- | --- |
| 30 segundos | Pequeño e inmediato | Una venta: monedas que suenan y número que salta |
| 5 minutos | Una compra | Mejora de cocina o de vehículo |
| 20 a 30 minutos | Un desbloqueo | Arma, vehículo o una tajada nueva del mapa |
| Cada sesión | Un cierre | Los tres encargos completos y el resumen de lo ganado |
| Cada día | Regreso | Racha, dulce del día, cosecha de las fincas |
| Cada semana | Meta de grupo | Territorios y contrato de banda |
| Cada 6 semanas | Novedad | Temporada con dulce legendario |

### Sorpresas que se ganan jugando

- **Cliente generoso:** 1 de cada 10 ventas paga el triple.
- **Dulce dorado:** 1 de cada 50 producciones sale dorado y vale 20 veces más.
- **Por un pelo:** pasar rozando una patrulla sin ser atrapado da fama extra.
- **Caja caída:** a veces aparece en la carretera una caja de un camión, y el primero que llega se la queda.

Ninguna sorpresa se compra con Robux: todas salen de jugar.

### Límites del enganche

El público de Roblox es joven, y estos límites son también los que hacen que un jugador vuelva por gusto y no por presión.

- Sin azar pagado: nada de cajas aleatorias con Robux.
- Sin castigo por faltar: lo acumulado tiene tope, pero nada se pierde por no entrar.
- Sin relojes que presionen a pagar: acelerar con azúcar dorada es comodidad, nunca la única salida.
- Con puntos naturales para parar: cada entrega cerrada es un buen momento para salir, y el juego lo muestra.

## Flujo de acontecimientos por zona

Cada zona tiene un ritmo normal y un evento que lo rompe, para que el mundo se sienta vivo aunque el jugador no haga nada. Los eventos se anuncian 30 segundos antes y se marcan en el mapa.

| Zona | Ritmo normal | Evento | Cada cuánto | Qué provoca |
| --- | --- | --- | --- | --- |
| Colegio | Patio vacío; sirve para practicar puntería | Hora del recreo: salen los niños y ronda el Coordinador | Cada hora, 10 minutos | Todos corren al centro a vender al doble |
| Barrio | De día hay más clientes; de noche menos, pero pagan más | Fiesta de cuadra: una tienda al azar triplica su demanda 3 minutos | Cada 20 minutos | Carrera entre jugadores por llegar primero |
| Carreteras | Los retenes cambian de lugar cada 10 minutos | Operativo: toda la policía se va a una carretera y la otra queda libre | Cada 15 minutos | Decidir entre la ruta segura y larga o la corta y vigilada |
| Territorios | Escaramuzas pequeñas entre semana | Guerra de territorios | Sábado y domingo | Las bandas se organizan para atacar y defender |
| Fincas | La cosecha se acumula | Inspección sanitaria con un minuto para esconder todo | Una vez por sesión, al azar | Carrera contra el reloj en tu propia finca |
| Internado | Horario fijo: comedor, patio y apagado de luces | Cada cambio de horario abre una ruta de fuga distinta | Cada 2 minutos | Planear la fuga en vez de solo esperar |
| Todo el mapa | Tráfico y clima normales | Lluvia de dulces: una avioneta suelta cajas en un anillo al azar | Cada 30 minutos | Todo el servidor converge en el mismo punto |
| Todo el mapa | Vigilancia normal | Toque de queda dental: estrellas y premios al doble por 5 minutos | Cada 45 minutos | El momento de mayor riesgo y mayor ganancia |

## Ambientación paisa

El juego ocurre en Villa Almíbar, una ciudad inventada en un valle estrecho de montaña, con un río en el fondo y barrios trepados en las laderas. Toma la cultura, la arquitectura y el habla paisa de los años de teléfono público y bus escalera, sin nombrar ciudades reales, sitios reales ni hechos de personas reales.

| Lugar | Nombre en el juego | Inspiración cultural | Anillo |
| --- | --- | --- | --- |
| Ciudad | Villa Almíbar | Ciudad de valle con laderas pobladas | Todo el mapa |
| Río | Río Melao | Río que parte el valle, con puentes | Entre anillos 1 y 2 |
| Barrio del jugador | El Mecato | Barrio popular en ladera, de tienda en cada esquina | 1 |
| Barrios rivales | Chicle Alto, La Mentolada y Bombón Viejo | Barrios vecinos con su propia cancha y su parque | 3 |
| Pueblo del campo | San Arequipe | Pueblo de plaza, kiosco y casas de zócalo de colores | 4 |
| Carretera de montaña | La Trocha del Almidón | Vía de curvas, neblina y derrumbes | 2 y 4 |

### Cómo se ve cada zona

- **El Mecato:** casas de dos pisos pegadas una a otra, ladrillo a la vista o fachadas de colores vivos, balcones con materas, rejas en las ventanas, tejas de barro y terrazas con ropa colgada. Cables cruzando la calle, tanques de agua en los techos y escaleras largas entre cuadras.
- **La esquina:** tienda con reja y mostrador, aviso de gaseosa inventada, banca afuera, teléfono público, un perro dormido y un carrito de mazamorra.
- **El parque:** iglesia de torre alta, una ceiba grande, bancas, palomas, vendedores y la cancha de microfútbol al lado.
- **Las rutas:** carretera de dos carriles pegada a la montaña, barranco a un lado, buses escalera pintados, estaderos de teja y avisos pintados a mano.
- **San Arequipe:** plaza empedrada con kiosco, casas de tapia con zócalo y puertas de colores, balcones de madera con flores.
- **Las fincas:** casa de corredor con chambrana, materas colgantes, patio de secado, establo y cafetal o cañaduzal en pendiente.
- **El internado:** edificio blanco y frío en lo alto de una loma, lo único sin color del mapa.

### Escala

Los edificios y objetos van a escala real; las distancias entre zonas van comprimidas, como en cualquier juego de mundo abierto, para que cruzar el mapa tome minutos y no horas. Se toma 1 stud de Roblox como 0,3 metros aproximados.

| Elemento | Medida real | En studs |
| --- | --- | --- |
| Puerta de casa | 1 m de ancho por 2,1 m de alto | 3 por 7 |
| Altura de un piso | 3 m | 10 |
| Fachada de casa de barrio | 6 m de ancho, dos pisos | 20 de ancho por 20 de alto |
| Andén | 1,2 m | 4 |
| Calle de barrio | 6 m | 20 |
| Callejón | 2 m: pasa la moto, no la patrulla | 7 |
| Carretera | 7 m | 23 |
| Tienda de esquina | 5 m por 6 m | 17 por 20 |
| Teléfono público | 2,2 m de alto | 7 |
| Cancha de microfútbol | 15 m por 25 m | 50 por 83 |
| Colegio completo | 60 m por 80 m | 200 por 270 |

| Zona | Distancia al colegio | Tiempo en bicicleta | Tiempo en moto |
| --- | --- | --- | --- |
| Borde del barrio | 250 m | 45 segundos | 20 segundos |
| Fin de las rutas | 600 m | 2 minutos | 50 segundos |
| Territorios | 900 m | 3 minutos | 75 segundos |
| Fincas | 1,4 km | No llega | 2 minutos |
| El borde | 1,8 km | No llega | Solo por aire o capturado |

Las medidas son de partida. Con un mapa de este tamaño hay que activar la carga por zonas de Roblox para que corra en celulares.

### El terreno como dificultad

| Terreno | Efecto | A quién favorece |
| --- | --- | --- |
| Subida de ladera | La bicicleta pierde casi la mitad de la velocidad; la moto pierde poco | Al que invirtió en vehículo |
| Bajada | Mucha velocidad y frenado largo | Al que conoce las curvas |
| Escaleras entre cuadras | Solo a pie; ningún vehículo pasa | Al jugador que huye de una patrulla |
| Callejones | Pasan bicicleta y moto; la patrulla no | Al que conoce el barrio |
| Puentes del río | Pasos obligados donde se ponen retenes | A la policía |
| Trocha embarrada | Con lluvia, el vehículo patina y la carga puede caerse | A nadie: es el riesgo de la ruta corta |
| Neblina de montaña | Se ve poco, pero las patrullas tampoco te ven | Al que se arriesga |
| Aguacero de la tarde | Al azar: calles lisas y menos clientes en la calle | A quien tenga la bodega llena |

## Colombia entera: regiones y calle

El valle es paisa, y cada ciudad lejana trae otra región del país con su habla, su música, su comida y su forma de construir. Todo va en tono de barrio: callejero, recursivo y con humor, sin groserías.

| Región | Dónde aparece | Cómo se ve | Cómo hablan | Música propia | Dulces de la región | Transporte |
| --- | --- | --- | --- | --- | --- | --- |
| Paisa | Villa Almíbar y San Arequipe | Laderas, ladrillo, balcones con materas, zócalos de colores | "Quiubo pues, parce", "hágale, mijo" | Parranda, carrilera, bambuco | Arequipe, panelitas, natilla, solteritas | Bus escalera, moto |
| Rola | Alto Frío | Ciudad fría y gris, edificios de ladrillo oscuro, gente de ruana y paraguas, neblina | "Sumercé", "vecino", "qué pena con usted" | Pasillo y cuerdas andinas | Obleas, postre de natas, cuajada con melao | Buseta que no para donde uno quiere |
| Caleña | Valle Caña | Calor, casas bajas, palmas, cañaduzales, canchas de baile | "Mirá ve", "oís", "vamos de borondo" | Salsa | Manjar blanco, cholado, champús | Campero viejo y bicicleta |
| Costeña | Puerto Cocada | Mar, casas de colores con balcón de madera, hamacas, muelle | "Ajá, mi llave", "eche", "cógela suave" | Vallenato, cumbia y equipos de sonido enormes | Cocadas, alegrías, enyucado, bolis | Mototaxi y bus pintado |

Cada ciudad sale de su plantilla: la fría para Alto Frío, la de tierra caliente para Valle Caña y la de costa para Puerto Cocada.

### El habla de calle

| Palabra | Qué significa | Quién la usa |
| --- | --- | --- |
| Parce, parcero, nea | Amigo | Los muchachos del barrio |
| El parche | El grupo de amigos, o el lugar donde se reúnen | Todos |
| Parchar | Pasar el rato | Todos |
| La vuelta | El encargo o el trabajo | La banda |
| Camellar | Trabajar | Todos |
| Lucas | Plata | Tenderos y muchachos |
| Melo, qué nota, bacano | Está muy bueno | Clientes contentos |
| De una, sisas | Sí, ya mismo | Los muchachos |
| Pille | Mire | Trompo y los compañeros |
| El cucho, la cucha | El papá, la mamá | Los muchachos, nunca delante de ella |
| El tombo | El policía | La banda |
| Sapo | El que delata | Todos; el peor insulto del barrio |
| Visaje | Llamar la atención | "No dé visaje" es el consejo antes de un retén |

Son palabras limpias, pero hay que probar cada texto con el filtro de chat de Roblox antes de publicarlo, porque bloquea más de lo que parece.

### Cultura de calle en el juego

| Elemento | Cómo aparece |
| --- | --- |
| El parche de la esquina | Muchachos sentados en el andén con una grabadora; dan chismes y avisan de la policía |
| Carros de balineras | Carreras cuesta abajo en tablas con rodillos: minijuego de velocidad en las lomas |
| Bicicross | Saltos y trucos en bicicleta en un lote del barrio |
| Camisetas de equipo | Dos equipos inventados del valle, con colores propios y partido los domingos |
| Murales del barrio | Pintados por los vecinos; cuentan historias del valle y se desbloquean nuevos con la fama |
| La barbería | Poste de rayas y sillón: ahí se cambia el peinado y se oyen los mejores chismes |
| El lavadero de motos | Se limpia el vehículo y baja un poco el calor |
| Equipos de sonido | En la costa, torres de parlantes pintadas a mano que tapan cualquier motor |

## Decoración de cada espacio

Esta es la lista de lo que debe tener cada espacio para sentirse vivo. Lo fijo arma el lugar, los detalles lo hacen creíble y el toque callejero lo hace nuestro.

| Espacio | Lo fijo | Detalles que dan vida | Toque callejero |
| --- | --- | --- | --- |
| Calle de barrio | Andenes altos, postes de luz, tapas de alcantarilla, rejas | Materas en tarros, ropa tendida, tanques, antenas, sillas plásticas en la puerta | Cables enredados, tenis colgados de un cable, avisos pintados a mano |
| Escaleras del barrio | Escalones de cemento, pasamanos de tubo, descansos | Peldaños pintados de colores, materas en los bordes, un gato | Nombres pintados, una banca improvisada con tabla y ladrillos |
| Tienda de esquina | Mostrador, reja, estantes, nevera, frascos de vidrio | Canastas de gaseosa apiladas, bultos, balanza, racimo colgado, calendario viejo | Letrero de "hoy no fío, mañana sí", cuaderno de fiados, radio prendido |
| Casa del jugador: sala | Sofá con forro, mesa de centro, televisor de perilla | Carpetas tejidas, retratos familiares, porcelanas, cortinas de flores | El control del televisor amarrado con caucho |
| Casa del jugador: cocina | Fogón, poceta, alacena | Ollas colgadas, arepas en la parrilla, colador de tela, termo | El molino de maíz atornillado a la mesa |
| Casa del jugador: pieza | Camarote, mesa de tareas, ropero | Cuadernos, balón, afiches de equipos inventados | El escondite bajo la cama y una tabla suelta en el piso |
| Cocina clandestina | Estufa, olla grande, mesa de empaque | Bultos de azúcar, frascos, cucharón de palo, vapor | Ventana tapada con cartón y un ventilador viejo para sacar el olor |
| Salón del colegio | Pupitres, tablero verde, escritorio | Cartelera, mapa colgado, borrador con tiza, ventanales | Chicles bajo los pupitres y nombres rayados en la madera |
| Patio del colegio | Tarima, asta de bandera, cancha, bebedero | Bancas, árbol con sombra, caneca, campana | Rayuela pintada en el piso y un balón en el techo |
| Parque del barrio | Iglesia, ceiba, bancas, faroles | Palomas, vendedor de helados, fuente, kiosco | Mesa de parqués con señores y el lustrabotas |
| Cancha | Piso de cemento, arcos, gradería corta | Malla rota, líneas desgastadas, luminaria | Arcos oxidados y un mural del equipo del barrio |
| Paradero | Techo de teja, banca, tablero | Poste con placa de la calle, caneca | Calcomanías y un vendedor de tinto con termo |
| Carretera | Barandas, señales, mojones | Estaderos, puestos de fruta, derrumbes viejos | Avisos pintados en las piedras |
| Bodega | Estantes, portón metálico, bombillo colgante | Estibas, cajas, carretilla, bultos | Una hamaca y un radio para el que cuida |
| Finca | Corredor con chambrana, patio, establo | Materas colgantes, taburetes de cuero, hamaca, perro | Herramientas colgadas en la pared y botas de caucho en la entrada |
| Internado | Paredes blancas, rejas, comedor | Carteles sobre cepillado, bandejas de brócoli, reloj | Marcas de días rayadas en la pared |

### Receta de decoración por cuadra

Para que el barrio se vea parejo, cada cuadra de El Mecato lleva como mínimo:

- 2 postes con cables cruzando la calle.
- 1 tienda o negocio en una esquina.
- 6 fachadas de al menos 3 colores distintos, con su placa de dirección.
- 4 balcones con materas y 2 con ropa tendida.
- 1 elemento con vida: perro, gato, vecina en el balcón o señores en la banca.
- 1 detalle callejero: mural, aviso pintado o tenis en el cable.
- 1 escondite posible: callejón, escalera o puerta que se pueda tocar.

### Puestos y vendedores de calle

| Puesto | Qué vende | Dónde va |
| --- | --- | --- |
| Carrito de mazamorra | Mazamorra con bocadillo | Esquinas del barrio |
| Puesto de arepas | Arepas de chócolo y de queso | Frente a la cancha |
| Mango biche | Mango con sal y limón | Salida del colegio |
| Obleas | Obleas con arequipe: competencia legal a medias | Parque |
| Tinto en termo | Tinto y aromática | Paraderos |
| Helados de palito | Helados en nevera de icopor | Recorre las calles con campanita |
| Empanadas | Empanadas con ají | Afuera de la bodega y del taller |

## El colegio al detalle

El colegio es el tutorial completo del juego: en él se aprenden vender, esconderse, huir y regatear antes de salir al barrio. Se llama Institución Educativa Villa Almíbar y ocupa una manzana.

| Espacio | Tamaño | Para qué sirve en el juego |
| --- | --- | --- |
| Patio central | 30 m por 40 m | Zona de ventas del recreo, con la tarima de la formación |
| Ocho salones en dos pisos | 6 m por 8 m cada uno | Escondites bajo los pupitres y clientes por la ventana |
| Corredores con chambrana | 2,5 m de ancho | Rutas de huida con línea de visión hacia el patio |
| Tienda escolar | 4 m por 5 m | La competencia: vende solo fruta y galletas sin azúcar |
| Baños | 5 m por 6 m | El mejor escondite, y el más vigilado |
| Coordinación | 4 m por 5 m | Ahí está el cajón con los dulces confiscados, que se puede recuperar |
| Cancha | 15 m por 25 m | Partido del recreo: distrae al Coordinador |
| Portón y portería | 4 m de ancho | La barrera del capítulo 1 |

### La rutina del colegio

1. **Formación:** todos en filas en el patio. Vender aquí es lo más arriesgado y lo mejor pagado.
2. **Clase:** patio vacío; se vende pasando dulces por las ventanas de los salones.
3. **Recreo:** el patio se llena, hay partido en la cancha y el Coordinador ronda.
4. **Salida:** el portón se abre y los niños compran para el camino.

### El Coordinador Tiza, primer jefe

- **Quién es:** el coordinador de disciplina, de bata gris, silbato y planilla. Lleva 20 años persiguiendo chicles pegados bajo los pupitres.
- **Cómo se comporta:** ronda una ruta fija, se detiene donde oye bulla y revisa los baños cada cierto tiempo. Ve en cono hacia adelante y oye en círculo.
- **Qué hace si te ve:** pita, te persigue y confisca los dulces que cargas.
- **El observador:** cada captura es una anotación. A la tercera cita al acudiente, y eso dispara el regaño de la mamá.
- **La pelea del capítulo:** al final hay que recuperar el cajón de dulces de la coordinación y salir por el portón mientras él bloquea corredores. Se le frena con la cauchera, cerrando puertas y armando bulla en otro lado.

### Los compañeros

| Compañero | Trasfondo | Papel en el juego |
| --- | --- | --- |
| Trompo | El mejor amigo; nunca tiene plata pero conoce a todo el mundo | Te consigue clientes y avisa dónde anda el Coordinador |
| La Monitora | La mejor del salón; cree en las reglas pero le encantan las gomitas | Puede delatarte o cubrirte, según cómo la trates |
| Juancho Fiado | Siempre promete pagar mañana | Enseña el sistema de fiar: paga con interés o no paga |
| Los de once | Los grandes del colegio; compran por montones | Clientes grandes que piden rebaja |
| El Chismógrafo | Sabe todo lo que pasa y lo cuenta | Si le vendes caro, riega el rumor y bajan las ventas |
| La Nueva | Llegó de San Arequipe; su familia tiene finca | Adelanta el mundo de las fincas y abre un encargo del capítulo 7 |

## La familia y la casa

La casa del jugador es su primera base, y la familia es la primera "autoridad" que hay que esquivar. Todo ocurre en tono de comedia familiar.

| Familiar | Trasfondo | Papel en el juego |
| --- | --- | --- |
| Doña Cocada, la mamá | Trabaja todo el día y quiere que su hijo estudie; huele el azúcar a una cuadra | Medidor de sospecha, regaños y mandados |
| Doña Melcocha, la abuela | Fue la mejor dulcera del barrio hasta la prohibición | Cómplice: enseña recetas y cubre al jugador |
| Colombina, la hermanita | Tiene 7 años y quiere ayudar en todo | Carga unos dulces extra, pero hace bulla si la dejas por fuera |
| Turrón, el hermano mayor | Tiene la única bicicleta de la casa y la presta a cambio de favores | Préstamo de la bicicleta antes de tener una propia |
| El tío Buñuelo | Camionero que pasa cada tantos días con historias de carretera | Adelanta las rutas y trae ingredientes raros |

### El regaño de la mamá

- **Sospecha:** sube cuando llegas tarde, con azúcar en la camisa, con anotaciones del colegio o con dulces mal escondidos bajo la cama.
- **El regaño:** al llenarse la sospecha, la mamá te espera en la puerta con los brazos cruzados. Hay una escena corta de cantaleta y el jugador elige excusa.
- **La excusa:** una buena la calma; una mala lo empeora. La abuela puede meterse a salvarte una vez al día.
- **El castigo:** un mandado obligatorio, como ir por la leche o llevarle algo a una vecina. Dura un minuto y casi siempre deja algo útil: un cliente nuevo, un atajo, un chisme.
- **Cómo bajarla:** hacer mandados por iniciativa propia, llegar temprano y esconder bien la mercancía.

El castigo nunca quita dinero ni progreso: cuesta un minuto y abre contenido.

## Vender en el barrio

### El regateo

Cada venta a un tendero es una negociación corta de tres turnos, y el precio final se mueve hasta un 20 % hacia arriba o hacia abajo del precio base.

1. El tendero ofrece un precio según su demanda y la confianza que te tiene.
2. El jugador elige: aceptar, pedir más, o pedir más con un argumento, como "está recién hecho" o "en la otra tienda me lo pagan mejor".
3. El tendero cede, se planta o se ofende. Su paciencia se ve en una barra.

- **Confianza:** sube con entregas cumplidas y baja si lo dejas esperando. Con confianza alta, ofrece mejor desde el principio.
- **Cada tendero regatea distinto:** uno cede rápido, otro es duro pero paga puntual, otro cambia de ánimo según el día.
- **Pasarse tiene costo:** si se ofende, no compra por unos minutos.

### El fiado

- El tendero o el cliente anota la deuda en el cuaderno y paga después, con un poco más.
- Algunos pagan siempre; otros se hacen los locos y hay que ir a cobrar.
- Fiar sube la confianza del barrio, que es lo que después te abre las puertas para esconderte.

### Tipos de encargo de dulces

| Encargo | Qué pide | Qué lo hace divertido |
| --- | --- | --- |
| Entrega a domicilio | Llevar un pedido a una casa antes de que se acabe el tiempo | La ruta más corta tiene escaleras o un perro |
| Pedido de fiesta | Una cantidad grande para una primera comunión o un cumpleaños | Hay que producir y juntar con anticipación |
| Antojo raro | Un dulce que aún no sabes hacer | Obliga a buscar la receta o el ingrediente |
| Cobro | Recoger lo que te deben | El deudor se esconde o regatea la deuda |
| Mandado de la mamá | Un favor sin dulces | Abre atajos, clientes y chismes |
| Reto de un rival | Vender más que otro vendedor en una hora del recreo | Competencia directa con marcador |

## El barrio vivo

### Objetos del barrio que se usan

| Objeto | Qué hace en el juego |
| --- | --- |
| Teléfono público | Con una moneda: recibir encargos, llamar a Maestro Tuerca por una grúa, avisar a la banda, o pedirle a Trompo que distraiga a la policía. Timbra solo cuando hay un encargo especial cerca |
| Cuaderno de fiados | En cada tienda; muestra quién te debe y cuánto |
| Radio de pilas | En tiendas y casas; anuncia eventos y operativos antes de que salgan en el mapa |
| Televisor de perilla | Pasa el noticiero de Lola Paleta con tus hazañas y el nivel de búsqueda |
| Carrito de mazamorra | Comida que da un rato de energía para correr más |
| Tienda de arepas | Lo mismo, y además la dueña te esconde si eres cliente |
| Bus escalera | Transporte lento y barato entre anillos; adentro la policía no te busca |
| Cancha | Partidos de microfútbol que juntan gente: más clientes y menos vigilancia |
| Juegos de calle | Trompo, canicas y parqués como minijuegos para ganar monedas y confianza |

### Esconderse en casas ajenas

1. Con una patrulla encima, el jugador puede tocar cualquier puerta del barrio.
2. El vecino abre según la confianza del barrio y su propio carácter.
3. Adentro se elige escondite: bajo la cama, detrás de la cortina, en el solar o dentro del tanque del lavadero.
4. El agente toca, pregunta y a veces entra a mirar. Hay que quedarse quieto mientras pasa.
5. Al salir, quedas debiendo un favor, que llega después como mandado.

| Vecino | Trasfondo | Cómo reacciona |
| --- | --- | --- |
| Doña Rosalba | Vive en el balcón y sabe la vida de todos | Te esconde, pero después lo cuenta: sube la sospecha de la mamá |
| Don Hernán | Pensionado de mal genio con un perro bravo | Difícil que abra; si abre, el perro espanta al agente |
| La señora de las arepas | Madruga todos los días y quiere a todos los muchachos | Siempre abre si le has comprado |
| Los universitarios | Arriendan una pieza y viven estudiando | Abren a cambio de dulces |
| El profe jubilado | Fue maestro del colegio y odia al Coordinador Tiza | Abre siempre y además da pistas |
| La casa vacía | Nadie sabe de quién es | Escondite seguro, pero hay que encontrar la entrada |

### Lo que puede pasar por azar

| Encuentro | Qué pasa | Qué genera |
| --- | --- | --- |
| Perro callejero | Te persigue una cuadra y puedes soltar un dulce | Susto corto; darle un dulce lo vuelve tu amigo |
| Vecina que pide fiado | Te para en la calle con un antojo | Decidir entre plata hoy o confianza mañana |
| Bus escalera atravesado | Bloquea la calle descargando bultos | Buscar callejón o escaleras |
| Partido en la calle | Un balón te tumba la carga | Recoger rápido antes de que los niños se la lleven |
| Vendedor rival | Otro muchacho vende en tu esquina | Reto de ventas o alianza |
| Agente goloso | Un policía dental mira tu morral con ganas | Puede dejarte pasar por un dulce, o era una trampa |
| Aguacero | Todos corren a escampar bajo los aleros | Ventas rápidas a gente que no se puede ir |
| La mamá en la calle | Aparece haciendo vueltas | Esconderse o inventar excusa en el acto |
| Teléfono que timbra | Un público suena cuando pasas | Encargo especial de alguien desconocido |

### Vida y animaciones

- **Tenderos:** barren el andén al abrir, acomodan frascos, se asoman a la reja y apuntan en el cuaderno.
- **Vecinos:** señoras conversando de balcón a balcón, señores jugando parqués en la banca, niños con trompo y cometa.
- **Calle:** perros que se echan al sol, palomas que salen volando, ropa que se mueve con el viento, vapor en el carrito de mazamorra.
- **Jugador:** esconder dulces en el morral, tocar puerta, regatear con las manos, pedalear de pie en la subida, limpiarse el azúcar antes de entrar a la casa.
- **Policía Dental:** revisar con espejo de dentista, anotar en libreta, tocar puertas y asomarse a las ventanas.
- **Horas del día:** mañana de buses y uniformes, tarde de recreo y aguacero, noche de faroles, radios y menos gente.

### El habla

Los diálogos usan giros paisas limpios: "quiubo pues", "hágale", "mijo", "parce", "¿y a cómo me lo deja?", "no sea tan carero", "eso está muy bueno, pues". Sin groserías, porque Roblox filtra el lenguaje fuerte.

### Calendario del barrio

| Época | Evento en el juego |
| --- | --- |
| Agosto | Desfile de silleteros con silletas de dulces, y cometas en el cielo |
| Octubre | Disfraces: los niños piden dulces casa por casa y la demanda se dispara |
| Diciembre | Alumbrados en las calles, natilla y buñuelos, música parrandera en cada cuadra |
| Fin de año escolar | Entrega de notas: el observador del colegio se pone en cero |

## Trasfondo de los personajes principales

| Personaje | Su historia | Qué quiere |
| --- | --- | --- |
| Alcalde Apio | De niño nunca lo dejaron comer dulces y creció convencido de que eso lo hizo exitoso | Una ciudad sin una sola caries |
| Comandante Muelas | Dentista frustrado que quería ser policía; logró ser las dos cosas | Atrapar al Patrón y, en secreto, probar un arequipe |
| Doctor Sarro | Dirige el internado convencido de que el brócoli cura todo | Que nadie se fugue en su turno |
| Don Ábaco | Tendero de toda la vida; la prohibición casi le quiebra el negocio | Que la tienda vuelva a vender como antes |
| Maestro Tuerca | Arregló todos los buses escalera del valle | Carros rápidos y que le paguen a tiempo |
| La Chiclosa | Empezó igual que el jugador, en otro colegio | Ser la única dulcera de Villa Almíbar |
| Don Mentol | Vendedor de mentas sin azúcar, socio del alcalde | Que la prohibición dure para siempre |
| Lola Paleta | Quiere ser periodista y el periódico del colegio le queda chiquito | La mejor historia del valle: la tuya |

## Qué de todo esto entra al lanzamiento

Este nivel de detalle es mucho más que los capítulos 1 a 4 originales, así que se reparte por fases para que un equipo de tres pueda terminarlo.

| Fase | Entra |
| --- | --- |
| 1 a 4, lanzamiento | Colegio completo con su rutina y el Coordinador Tiza, El Mecato, familia con sospecha y regaño, regateo simple, teléfono público con encargos, tres vecinos para esconderse, cuatro encuentros al azar |
| 5 y 6 | Fiado, todos los vecinos, todos los encuentros, bus escalera, minijuegos de calle, barrios rivales |
| 7 en adelante | San Arequipe, fincas, clima completo, calendario del barrio |

## El mundo extenso

El mundo completo es un valle con 7 regiones, más ciudades lejanas que se van abriendo sin límite. Lo ya construido (colegio, casa con cocina, zigzag con tiendas y retenes, y los dos barrios en ladera) es la primera región y no se borra: todo lo demás crece alrededor.

| Región | Qué tiene | Se abre en | Qué se juega ahí |
| --- | --- | --- | --- |
| 1. Villa Almíbar bajo | Colegio, El Mecato, el zigzag | Capítulos 1 a 4 | Historia, tutorial, ventas y primeras huidas |
| 2. Barrios altos | Chicle Alto, La Mentolada, Bombón Viejo | Capítulo 6 | Territorios entre bandas |
| 3. El centro | Plaza mayor, mercado, terminal de buses, alcaldía, cuartel de la Policía Dental | Capítulo 5 | Ventas grandes, eventos de ciudad, el mayor riesgo |
| 4. La Trocha | Carreteras de montaña, estaderos, miradores, túneles | Capítulos 4 y 7 | Entregas largas y persecuciones |
| 5. Las veredas | Cuatro montañas con fincas en parcelas | Capítulo 7 | Producción y disputa territorial |
| 6. San Arequipe | Pueblo de plaza, feria y trapiche | Capítulo 8 | Comercio de ingredientes y fiestas |
| 7. El borde | Internado Sin Azúcar, pista y hangar | Capítulos 8 y 9 | Cárcel, fugas y exportación |
| Más allá | Tres ciudades lejanas, y una nueva por renacimiento | Capítulos 8 y 10 | Juego sin final |

### Cómo se hace infinito sin trabajo infinito

- **El valle es un solo mapa** con carga por zonas, para que corra en celulares.
- **Las ciudades lejanas son lugares separados** dentro del mismo juego. Se llega en avioneta o en bus de línea, con una pantalla de viaje.
- **Cada ciudad se arma con plantillas:** tres modelos de ciudad (de clima frío, de tierra caliente y de costa) que se combinan con distinto trazado, tiendas y precios.
- **Cada renacimiento abre una ciudad** con precios más altos, policía más dura y un dulce propio de la región.

## Moverse sin mapa: paraderos y señales

No hay minimapa. El jugador se ubica como en un barrio de verdad: por paraderos, direcciones, letreros y preguntando.

| Elemento | Cómo funciona |
| --- | --- |
| Paradero | Caseta con un tablero pintado de la zona: muestra las tiendas, los puntos y las rutas que el jugador ya descubrió o que le contaron |
| Rutas de bus | Tres líneas de colores: la circular de El Mecato, la del zigzag al centro y la chiva a San Arequipe. Se paga pasaje y se puede saltar el recorrido después de la primera vez |
| Direcciones paisas | Calles y carreras numeradas, con placas en las esquinas: "Carrera 4 con Calle 12" |
| Preguntar | Cualquier vecino da indicaciones a su manera: "siga derecho dos cuadras y voltee donde el perro" |
| Puntos de referencia | La torre de la iglesia, la ceiba del parque, el tanque del acueducto y la antena de la loma se ven desde lejos |
| Chismes | Un tendero o un compañero te cuenta de un lugar, y ese lugar aparece en los tableros |
| Bus como refugio | Adentro la policía no te busca, salvo con 4 estrellas o más: ahí un retén puede parar el bus |

Para que un jugador nuevo no se pierda, el encargo activo muestra una flecha suave hacia su destino. Se puede apagar, y en modo competitivo no existe.

## Fincas en la montaña: disputa territorial

Hay dos clases de finca, y la diferencia es lo que mantiene el juego justo: la propia nunca se pierde, la disputada cambia de manos.

| Clase | Dónde está | Se puede perder | Qué da |
| --- | --- | --- | --- |
| Finca propia | En tu parcela personal de la vereda | No | Tu producción de ingredientes y tu mansión |
| Finca en disputa | En las parcelas compartidas de cada vereda, 6 por vereda | Sí, el control rota | Un bono de producción para toda la banda mientras la controle |

### La toma de una finca

1. Una banda declara la toma de una finca en disputa durante la hora de disputa.
2. Los dueños actuales reciben el aviso y tienen 2 minutos para llegar.
3. La toma dura 10 minutos: gana quien controle más tiempo los tres puntos, que son la casa, la bodega y el portón.
4. Se pelea con las armas de dulce y con trampas puestas de antemano.
5. La banda que gana controla la finca; la que pierde conserva todo lo suyo y solo deja de recibir el bono.

### La redada de la Policía Dental

- **Calor:** cada propiedad tiene un medidor que sube con el volumen de producción y con las persecuciones que terminan cerca.
- **Aviso:** al llenarse, la radio anuncia el operativo 2 minutos antes.
- **Qué se puede hacer:** esconder la mercancía en la despensa secreta, sacarla en vehículo o defender la entrada.
- **Si la redada gana:** la propiedad queda sellada con cinta de "clausurado" entre 30 minutos y 2 horas, y se confisca hasta el 30 % de lo almacenado ahí.
- **Lo que nunca se pierde:** el edificio, las mejoras, la decoración y el dinero guardado.

La redada aplica igual a fincas, bodegas y a la mansión.

### Límites para que siga siendo competitivo

| Límite | Valor de partida | Qué evita |
| --- | --- | --- |
| Fincas en disputa por banda | Máximo 3 | Que una banda grande se quede con todo |
| Hora de disputa | Dos ventanas diarias de 1 hora y la guerra del fin de semana | Tomas a las 3 de la mañana cuando nadie defiende |
| Escudo tras cambio de dueño | 24 horas | Que una finca cambie de manos sin parar |
| Tomas declaradas por banda | 2 al día | El acoso a una misma banda |
| Protección de novato | 3 días o hasta el capítulo 7 | Que un jugador nuevo sea atacado sin poder defenderse |
| Ligas de bandas | Las tomas solo se cruzan entre bandas de tamaño parecido | Peleas imposibles |
| Nómina | Crece con cada propiedad | Que crecer sea gratis |
| Calor | Sube más rápido mientras más grande es el imperio | Que el líder nunca sea alcanzado |
| Cierre de temporada | Cada 6 semanas las fincas en disputa quedan libres y se premia por puesto | Que las posiciones queden fijas para siempre |

## La historia de crecimiento

El juego cuenta cómo un niño del barrio crece hasta volverse leyenda, en cuatro etapas. El personaje no envejece por fuera, pero cambia cómo lo tratan, dónde vive y qué le importa.

| Etapa | Capítulos | Cómo lo llaman | Dónde vive | Qué siente el jugador |
| --- | --- | --- | --- | --- |
| El pelao | 1 a 3 | "Mijo" | La casa de la mamá | Travesura: esconderse de la mamá y del Coordinador |
| El muchacho | 4 a 6 | "Parce" | Una pieza encima de la bodega | Riesgo y amistad: la primera banda y la primera rival |
| El don | 7 a 9 | "Don" | La finca y la mansión | Responsabilidad: mucha gente depende de él y hay mucho que perder |
| La leyenda | 10 en adelante | "Patrón" | Donde quiera | Legado: su heredero empieza de nuevo |

- **La mamá cambia con las etapas:** primero regaña, después se preocupa, al final manda saludos por el teléfono público.
- **El barrio lo recuerda:** los vecinos lo saludan distinto y Lola Paleta escribe su historia por entregas.
- **No hay final:** la prohibición sigue en pie y la historia no se cierra. Después del capítulo 9 el mundo queda abierto y cada jugador escribe la suya.

## Qué hace cada uno en el mundo extenso

| Sistema | Andrés crea | Santiago define | Pablo programa |
| --- | --- | --- | --- |
| Paraderos y rutas | Caseta con tablero pintado, bus escalera, trazado de 3 rutas, placas de calles | Pasajes, tiempos de recorrido, qué muestra cada tablero, numeración de calles | Descubrimiento de lugares, tablero que se actualiza, viaje en bus, flecha del encargo |
| Montañas y veredas | Terreno de 4 montañas, juego de piezas modulares de finca, miradores, caminos | Parcelas por vereda, bonos de cada finca, costos | Carga por zonas, propiedad de parcelas, cosecha |
| Tomas | Banderas, puntos de control, trampas y sus efectos | Duración, escudos, cupos, ligas, premios de temporada | Captura de puntos, ventanas horarias, emparejamiento por liga |
| Redadas | Camión de la Policía Dental, cinta de clausurado, animación de registro | Medidor de calor, porcentaje confiscado, tiempo de sellado | Comportamiento de la redada, despensa secreta, sellado |
| Ciudades lejanas | Tres plantillas de ciudad y sus piezas | Precios y dificultad por renacimiento, dulce de cada región | Lugares separados, viaje entre ellos, armado por plantilla |
| Etapas de vida | Atuendos y vivienda de cada etapa | Hitos, textos de trato, cartas de la mamá | Sistema de etapa que cambia saludos y diálogos |

De todo esto, al lanzamiento solo entran dos paraderos con su tablero y las placas de calles. Lo demás empieza en la fase 5.

## Dificultad con peso

El juego es difícil a propósito: cada zona nueva se gana pasando una prueba, y haberla pasado se nota. Es difícil pero justo, porque toda derrota se puede explicar y lo que se pierde tiene techo.

- **La preparación decide.** Conocer los callejones, tener el vehículo correcto y llegar con aliados pesa más que los reflejos.
- **Sin ayudas desde el capítulo 4.** La policía no afloja y los rivales no esperan.
- **Racha de entregas perfectas.** Cada entrega seguida sin captura sube un multiplicador de ganancia que se pierde entero al primer fallo. Seguir o guardar es decisión del jugador.
- **Toda derrota se entiende.** El jugador vio la patrulla, oyó la sirena o ignoró el aviso de la radio. Nada lo atrapa por sorpresa total.
- **El logro se ve.** Cada prueba da un título sobre el nombre, con el porcentaje de jugadores que la ha pasado.

### Detonantes: las pruebas que abren el mundo

Son 8 momentos fijos de la historia. No se saltan, no se compran y se pueden intentar las veces que haga falta.

| # | Detonante | Qué abre | La prueba | Por qué es difícil |
| --- | --- | --- | --- | --- |
| 1 | La salida del colegio | El Mecato | Recuperar el cajón de dulces y cruzar el portón con el Coordinador Tiza encima | Todo es sigilo: solo hay cauchera |
| 2 | El primer pedido grande | La cocina y el resto de tiendas | Producir y entregar un pedido de fiesta a tiempo, con la mamá sospechando | Administrar tiempo, escondite y excusas a la vez |
| 3 | La subida del zigzag | Las rutas | Cruzar los tres retenes con carga completa en una sola corrida | No hay punto de guardado entre retenes |
| 4 | La noche de la bodega | Las bandas | Defender la bodega durante cinco oleadas | Hay que repartir trampas y munición que cuesta dulces |
| 5 | La caída de La Chiclosa | Los barrios altos | Vencer a la jefa rival en su guarida | Tres fases y un terreno que ella conoce mejor |
| 6 | La primera cosecha | Las veredas | Sacar la cosecha completa durante la primera redada | Reloj en contra y caminos de montaña |
| 7 | El primer vuelo | San Arequipe y las ciudades lejanas | Aterrizar la avioneta cargada con neblina | Un solo intento por carga |
| 8 | La gran persecución | El renacimiento | Cruzar todo el valle con cinco estrellas y el Comandante Muelas detrás | Junta todo lo aprendido en una sola corrida |

Se pueden intentar en grupo, y la prueba se endurece según cuántos entren. El título de quien la pasó solo es distinto del de quien la pasó acompañado.

## Después del capítulo 9: juego libre

No hay final. Al pasar la gran persecución el valle queda abierto del todo, y el capítulo 10 es un renacimiento opcional que se puede repetir sin límite. Desde ahí el juego es cooperativo: cultivar, enviar, cumplir misiones, disputar territorio y descubrir la historia del valle.

| Actividad | Solo o en grupo | Qué da |
| --- | --- | --- |
| Convoy de exportación | De 2 a 6 jugadores | La mayor ganancia del juego, repartida entre quienes llegan |
| Cosecha en compañía | Visitando fincas de amigos | Bono para el dueño y para el que ayuda |
| Encargos encadenados | Solo | Historias cortas de vecinos, en varios pasos, con premio único al final |
| Contratos de banda | La banda entera | Mejoras permanentes de la bodega común |
| Tomas y defensas | Banda contra banda | Control de fincas en disputa y puesto en la temporada |
| Recetas perdidas | Solo o en grupo | Páginas del recetario de antes de la prohibición, escondidas por todo el valle |
| Leyendas del valle | En grupo, de noche | Eventos raros en la trocha y el monte, con premios que no salen en otro lado |
| Mercado entre jugadores | Libre | Intercambio de recetas, ingredientes y dulces legendarios |

### Cómo se cuenta la historia del valle

No hay escenas largas. La historia está regada por el mundo y cada jugador arma la suya con lo que encuentra.

- **Cartas y recortes:** en cajones, bodegas y casas vacías.
- **La radio:** noticias que cambian según lo que hacen los jugadores del servidor.
- **Los chismes:** cada vecino cuenta su versión, y no siempre coinciden.
- **El periódico de Lola Paleta:** un número por semana con lo que pasó en el valle.
- **Murales y avisos pintados:** cuentan cómo era Villa Almíbar antes de la prohibición.

## Tu propia historia

El jugador no sigue un solo camino: hay cuatro maneras de crecer, se pueden mezclar, y el valle lo trata según lo que ha hecho.

| Camino | Se sube haciendo | Ventaja propia | Cómo lo ven |
| --- | --- | --- | --- |
| Comerciante | Tiendas, regateo y fiado | Mejores precios y más puertas abiertas para esconderse | El que siempre cumple |
| Transportador | Entregas, rutas y convoyes | Vehículos más rápidos y escondites extra | El que llega como sea |
| Finquero | Producción, recetas y fincas | Más cosecha y recetas que nadie más hace | El que tiene lo mejor |
| Jefe de banda | Territorios, tomas y defensas | Bonos para toda la banda | El que manda |

### Decisiones que el valle recuerda

| Decisión | Un camino | El otro camino |
| --- | --- | --- |
| Juancho no paga | Perdonarle: sube la confianza del barrio | Cobrarle: plata hoy y menos puertas mañana |
| La Chiclosa propone alianza | Aceptar: paz y rutas compartidas | Rechazar: guerra y todo su territorio en juego |
| Un rival cae en un retén | Cubrirlo: te debe un favor | Dejarlo: te quedas con su esquina |
| La nómina de los trabajadores | Pagar bien: rinden más y no hablan | Pagar poco: más ganancia y riesgo de que alguno cuente |
| El agente goloso | Darle el dulce: te deja pasar | Negarte: sin deudas con nadie de la policía |

Hay dos medidores que salen de esas decisiones: **palabra**, que es cuánto confían en ti, y **respeto**, que es cuánto te temen. Ninguno es el correcto; cada uno abre puertas distintas.

## Qué se paga y qué no

El camino difícil es el juego. Lo que se paga acorta la espera, nunca la prueba, porque un título que se puede comprar deja de valer para todos.

| Se puede comprar | No se compra |
| --- | --- |
| Tiempo: acelerar producción y cosecha | Los 8 detonantes y sus títulos |
| Comodidad: más bodega, segunda receta activa | Ventaja en tomas, defensas y asaltos |
| Apariencia: atuendos, vehículos de colección, decoración | Puestos en las tablas y en la temporada |
| El pase de temporada | Mejor resultado en el regateo o en la palabra y el respeto |
| Ayudas de cultivo, solo fuera del modo competitivo | Armas más fuertes |

## Momentos grandes: retenes, convoyes y el golpe

Son las tres situaciones clásicas del género de contrabando, convertidas en momentos de juego con dulces. Las escenas, los chistes y los diálogos son propios: ninguno copia una escena de una serie ni un hecho de una persona real.

### Dulces prohibidos según la ciudad

Cada ciudad lejana prohíbe un dulce distinto, y lo prohibido es lo que mejor se paga. Eso es lo que da sentido a transportar.

| Ciudad inventada | Clima | Dulce prohibido | Cuánto paga | Retenes en el camino |
| --- | --- | --- | --- | --- |
| Alto Frío | Capital de montaña | Arequipe | 3 veces el precio del valle | 6 |
| Valle Caña | Tierra caliente | Panelitas | 3 veces | 5 |
| Puerto Cocada | Costa | Bocadillo | 4 veces | 8 |

### El retén

En cada retén con carga el jugador tiene cuatro salidas, y ninguna es segura.

| Salida | Cómo funciona | Si sale mal |
| --- | --- | --- |
| Esconder | La carga va en el escondite del vehículo; el agente revisa con su espejo de dentista | Decomiso de toda la carga |
| Convidar | Se le ofrece un dulce al agente para que mire a otro lado | Depende del agente: sube el precio o intenta arrestarte |
| Acelerar | Pasar de largo rompiendo la barrera | Dos estrellas de inmediato y patrullas detrás |
| Desviarse | Tomar la trocha o el callejón | Ruta más larga, embarrada y sin dónde reparar |

| Tipo de agente | Cómo es | Qué pasa si le ofreces |
| --- | --- | --- |
| El goloso | Mira el morral con ganas | Acepta uno y te deja pasar |
| El carero | Acepta, pero cada vez pide más | Sale caro y se acuerda de ti |
| El recto | No recibe nada de nadie | Dos estrellas e intento de arresto |
| El novato | Nervioso, primer día de turno | Puede dejarte pasar o llamar al jefe; es una moneda al aire |
| El jefe de retén | Solo aparece con convoyes | Cobra por vehículo y negocia como un tendero |

- **No se sabe quién es quién.** El tipo de agente se averigua por chismes, por la radio o por haberlo cruzado antes.
- **El chiste propio: el agente a dieta.** Jura que el Comandante le prohibió el dulce y decomisa "para destruir la evidencia". Si el jugador lo sigue a escondidas, lo ve comérsela detrás de la caseta, y desde ahí ese agente lo deja pasar gratis.
- **Arresto.** Si el agente recto te agarra, vas al Internado Sin Azúcar y pierdes la carga del viaje.

| Ruta | Retenes | Tipos que salen |
| --- | --- | --- |
| El zigzag | 3 | Goloso, novato |
| La Trocha hasta las fincas | 4 | Goloso, carero, novato |
| Camino a San Arequipe | 5 | Todos menos el jefe |
| Convoy a ciudad lejana | 5 a 8 | Todos, con un jefe de retén en el último |

### El convoy

1. La banda arma una caravana de hasta 8 vehículos, entre jugadores y conductores contratados.
2. Se elige la ruta y el orden: quién va adelante abriendo, quién lleva la carga cara y quién cierra.
3. En cada retén se revisa una parte de la caravana. Cada revisión fallida daña de 1 a 3 vehículos: llantas desinfladas, carga regada, motor desarmado.
4. Un vehículo dañado se repara ahí mismo con repuestos, lo que toma tiempo mientras llegan patrullas, o se abandona con su carga.
5. Lo que llega a la ciudad se vende al precio prohibido y se reparte entre los que llegaron.

- **Los repuestos ocupan espacio de carga.** Llevar más repuestos es llevar menos dulces.
- **El vehículo de adelante puede distraer.** Uno sin carga pasa primero y entretiene al agente.
- **Maestro Tuerca ofrece grúa** por el teléfono público, cara y lenta.
- **Ocho vehículos es el tope** para que el juego corra bien en celulares.

### El golpe a la Gran Panificadora

La Gran Panificadora es la única fábrica con licencia del alcalde para hornear pan dulce, es de Don Mentol y guarda las panochas en un horno con puerta de bóveda. Es el golpe más difícil y mejor pagado del valle.

| Dato | Valor de partida |
| --- | --- |
| Se abre | En el capítulo 8, con la misión C8\_05 |
| Jugadores | De 2 a 4 |
| Frecuencia | Una vez por semana por banda |
| Duración | 15 a 20 minutos, sin contar la preparación |

**Preparación.** Son tres tareas en cualquier orden, cada una es una misión corta, y saltarse una hace el golpe más duro.

| Tarea | Qué se hace | Qué facilita |
| --- | --- | --- |
| Reconocimiento | Entrar como cliente, memorizar las rondas de los vigilantes y encontrar las tres entradas: puerta principal, muelle de carga y ducto del horno | Muestra las rondas durante el golpe |
| El disfraz | Conseguir uniformes de panadero o el camión repartidor | Entrar sin levantar sospecha |
| Las herramientas | Masa pegajosa para trabar la campana de alarma y la llave del muelle, que tiene un trabajador | Más tiempo antes de que suene la alarma |

**Los papeles.**

| Papel | Qué hace |
| --- | --- |
| El de adentro | Entra disfrazado, traba la alarma y abre el horno |
| El cargador | Saca las bandejas; cada bandeja lo hace más lento |
| El conductor | Espera en el muelle y maneja la huida |
| El vigía | Vigila desde la esquina y avisa por el teléfono público cuando viene la ronda |

**El golpe, paso a paso.**

1. **Entrar** por una de las tres entradas, según lo preparado.
2. **Trabar la alarma:** un minijuego de pulso con la masa pegajosa.
3. **Abrir el horno:** hay que acertar una secuencia de temperaturas, con pistas del reconocimiento.
4. **Cargar:** cada bandeja de más es más ganancia y más segundos adentro. Decidir cuándo parar es la tensión del golpe.
5. **Salir:** al cruzar la puerta salen 4 estrellas para toda la banda.
6. **Huir:** las panochas se enfrían y pierden valor cada minuto, así que esconderse a esperar no sirve.

- **Si atrapan a uno,** va al internado y su parte se pierde; los demás pueden seguir.
- **La seguridad aprende.** Cada golpe logrado en la temporada suma un vigilante, un perro o una ronda más.
- **El premio:** las panochas se venden a precio de dulce legendario, y el primer golpe limpio da un título propio.

### Qué hace cada uno

| Sistema | Andrés crea | Santiago define | Pablo programa |
| --- | --- | --- | --- |
| Retenes y agentes | Caseta, barrera, cinco aspectos de agente, animación de revisión y del agente a dieta | Probabilidad de cada tipo por ruta, precio de convidar, daños | Las cuatro salidas, memoria de cada agente, arresto |
| Convoy | Vehículos con tres estados de daño, repuestos, grúa | Tope de vehículos, daño por retén, reparto de ganancia | Caravana, conductores contratados, reparación en ruta |
| Ciudades y prohibiciones | Tres ciudades por plantilla | Qué prohíbe cada una y cuánto paga | Precios por ciudad y viaje |
| El golpe | La Gran Panificadora por dentro y por fuera, horno con puerta de bóveda, uniformes, camión | Tiempos, valor de las panochas, enfriamiento, seguridad por temporada | Preparación, papeles, minijuegos, alarma y huida |

El retén con sus cuatro salidas puede entrar desde la fase 2. El convoy, las ciudades y el golpe empiezan en la fase 5.

## Misiones por capítulo

Son 59 misiones, entre 5 y 6 por capítulo, y la última de cada uno es su detonante o su logro de cierre. Siguen el crecimiento del personaje del juego por sus cuatro etapas; ninguna reproduce la vida de una persona real.

### Cómo se escribe una misión para programarla

Todas las misiones usan la misma ficha, para que Pablo programe un solo sistema y Santiago agregue misiones sin tocar código.

| Campo | Qué contiene | Ejemplo |
| --- | --- | --- |
| `id` | Identificador único | `Mision_C1_02` |
| `tipo` | Venta, entrega, sigilo, combate, producción, decisión, construcción o detonante | `sigilo` |
| `requisito` | Misión que debe estar cumplida antes | `Mision_C1_01` |
| `objetivo` | Evento que se cuenta, cantidad y filtro | `VentaRealizada`, 10, a `NPC_Estudiante` |
| `limites` | Tiempo, estrellas máximas, sin captura | Sin captura |
| `fallo` | Qué reinicia la misión | `JugadorCapturado` por `NPC_Coordinador` |
| `premio` | Pesos, fama y lo que desbloquea | 20 pesos, 5 de fama, `Arma_Cauchera` |
| `textos` | Diálogo de inicio y de cierre | Claves del archivo de textos |

```lua
Mision_C1_02 = {
	tipo = "sigilo",
	requisito = "Mision_C1_01",
	objetivo = { evento = "VentaRealizada", cantidad = 10, filtro = "NPC_Estudiante" },
	limites = { sinCaptura = true },
	fallo = { evento = "JugadorCapturado", por = "NPC_Coordinador" },
	premio = { pesos = 20, fama = 5, desbloquea = "Arma_Cauchera" },
	textos = { inicio = "C1_02_inicio", cierre = "C1_02_cierre" },
}
```

Los premios en pesos y fama de las tablas siguientes los fija Santiago en la tabla de datos; aquí solo se indica lo que cada misión desbloquea o enseña.

### Etapa 1: el pelao

**Capítulo 1. El recreo**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C1\_01 | Los cinco bombones | Vender los bombones que dio la abuela | 5 ventas a estudiantes | No falla | La venta |
| C1\_02 | Ojo con Tiza | Vender durante la ronda del Coordinador | 10 ventas sin captura | Te captura el Coordinador | El sigilo; da la cauchera |
| C1\_03 | Puntería | Tumbar latas en el patio y aturdir al Coordinador | 5 latas y 1 aturdimiento | No falla | El disparo |
| C1\_04 | El mandado | Llevar la leche a la casa sin oler a dulce | Llegar en 2 minutos con sospecha baja | Se acaba el tiempo | La sospecha de la mamá |
| C1\_05 | La campana | Aprovechar una hora del recreo completa | 30 ventas en un recreo | Termina el recreo | El evento del recreo; da el morral grande |
| C1\_06 | La salida del colegio | Detonante 1: recuperar el cajón y cruzar el portón | Cruzar el portón con el cajón | Captura: se reinicia desde la coordinación | Abre El Mecato; da la bicicleta |

**Capítulo 2. La esquina**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C2\_01 | Don Ábaco | Vender por primera vez a una tienda | Cerrar un regateo | El tendero se ofende: se reintenta | El regateo |
| C2\_02 | Tres tiendas | Repartir a tres tiendas en una sola salida | 3 entregas en 4 minutos | Se acaba el tiempo | Las rutas en bicicleta |
| C2\_03 | El fiado de Juancho | Decidir si se le perdona o se le cobra | Tomar la decisión | No falla | El fiado y la palabra |
| C2\_04 | La cuadra del perro | Entregar pasando por donde Don Hernán | Entrega hecha con la carga completa | El perro tumba la carga | Los encuentros al azar |
| C2\_05 | Tocar puerta | Esconderse de la mamá en casa de una vecina | Salir sin ser visto | La mamá te ve: regaño | Esconderse en casas ajenas |
| C2\_06 | Dueño de la cuadra | Ganarle la esquina al vendedor rival | Controlar 3 tiendas | No falla | Ingreso pasivo; abre la cocina |

**Capítulo 3. La cocina de la abuela**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C3\_01 | La receta de la abuela | Cocinar el primer arequipe | 1 arequipe sin quemar | Se quema: se repite | La producción |
| C3\_02 | Los ingredientes | Comprar leche y panela sin que la mamá pregunte | Volver con todo y sospecha baja | La sospecha se llena | Costos de producción |
| C3\_03 | Olor a dulce | Ventilar la cocina antes de que llegue la mamá | Abrir 3 ventanas en 40 segundos | Llega antes: regaño | Producir con riesgo |
| C3\_04 | Tres recetas | Aprender panelita y bocadillo | Producir 5 de cada una | No falla | El recetario |
| C3\_05 | Colombina ayuda | Hacer una entrega con la hermanita cargando | Llegar con ella y la carga | Colombina hace bulla y la ven | Llevar acompañantes |
| C3\_06 | El primer pedido grande | Detonante 2: pedido de fiesta a tiempo | Entregar 60 dulces en 8 minutos | Se acaba el tiempo | Abre el resto de tiendas; da la moto |

### Etapa 2: el muchacho

**Capítulo 4. La ruta**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C4\_01 | Primera subida | Entregar en el primer tramo del zigzag | 1 entrega arriba | Pierdes la carga | Manejar en pendiente |
| C4\_02 | El escondite | Instalar un escondite con Maestro Tuerca y pasar un retén | Pasar la revisión | Decomiso | Esconder la carga |
| C4\_03 | El agente goloso | Convidar a un agente por primera vez | Pasar convidando | Era el recto: huir | Los tipos de agente |
| C4\_04 | Dos estrellas | Perder a una patrulla por callejones y escaleras | Bajar a cero estrellas | Captura | La huida |
| C4\_05 | Crema al parabrisas | Usar la pistola de crema en persecución | Cegar 3 patrullas | No falla | Las armas en vehículo |
| C4\_06 | La subida del zigzag | Detonante 3: tres retenes en una corrida | Llegar arriba con la carga | Captura o decomiso | Abre las rutas |

**Capítulo 5. La banda**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C5\_01 | Bombombún | Enseñarle la ruta al primer repartidor | Él completa una entrega siguiéndote | Lo atrapan | Contratar repartidores |
| C5\_02 | La bodega | Comprar la bodega y llenarla | 100 dulces guardados | No falla | El almacén y la ausencia |
| C5\_03 | La primera nómina | Decidir cuánto se le paga a la banda | Tomar la decisión | No falla | La nómina y el respeto |
| C5\_04 | Entrega doble | Hacer un viaje de dos vehículos | Llegan los dos | Se pierde uno | La base del convoy |
| C5\_05 | El centro | Vender en el mercado del centro | 3 ventas con vigilancia alta | Captura | Abre el centro |
| C5\_06 | La noche de la bodega | Detonante 4: defender cinco oleadas | Bodega en pie al final | La bodega cae | Abre las bandas |

**Capítulo 6. La guerra del azúcar**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C6\_01 | Chicle en mis tiendas | Recuperar las tiendas donde entró la Banda del Chicle | 3 tiendas recuperadas | No falla | La competencia por tiendas |
| C6\_02 | La propuesta | Responder a la alianza que ofrece La Chiclosa | Tomar la decisión | No falla | Cambia las misiones siguientes |
| C6\_03 | Emboscada en el zigzag | Defender una entrega de un asalto | Llegar con la mitad de la carga o más | Pierdes más de la mitad | El asalto de rutas |
| C6\_04 | Bandera en Chicle Alto | Tomar el primer territorio | Controlar el punto 3 minutos | Te sacan del punto | Los territorios |
| C6\_05 | El soplón | Averiguar quién le cuenta tus rutas a la policía | Juntar 3 chismes y señalar al correcto | Señalar mal: baja la palabra | Investigar por chismes |
| C6\_06 | La caída de La Chiclosa | Detonante 5: vencerla en su guarida | Superar las tres fases | Toda la banda queda empalagada | Abre los barrios altos |

### Etapa 3: el don

**Capítulo 7. La finca**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C7\_01 | La parcela | Comprar la primera parcela con ayuda de la familia de La Nueva | Parcela comprada | No falla | Abre las veredas |
| C7\_02 | El primer ordeño | Producir leche en El Ordeño | 20 unidades de leche | No falla | Los ingredientes propios |
| C7\_03 | La cuadrilla | Contratar y asignar trabajadores | 3 trabajadores con tarea | No falla | El trabajo automático |
| C7\_04 | La casa grande | Levantar el primer módulo de la mansión y recibir a la mamá | Módulo construido y visita hecha | No falla | La mansión; cambia el trato de la mamá |
| C7\_05 | Inspección sanitaria | Esconder la producción antes de la revisión | Todo en la despensa en 1 minuto | Encuentran producto: decomiso | Las inspecciones |
| C7\_06 | La primera cosecha | Detonante 6: sacar la cosecha durante la redada | Cosecha completa fuera de la finca | Se pierde más de la mitad | Abre las fincas en disputa |

**Capítulo 8. El puente aéreo**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C8\_01 | El miedo de Merengue | Convencer al piloto con un vuelo bajito de práctica | Completar el circuito sin subir de la altura marcada | Subes demasiado: se asusta | Da el piloto |
| C8\_02 | Licencia de vuelo | Pasar el circuito de aros | Todos los aros en el tiempo | Se acaba el tiempo | Volar la avioneta |
| C8\_03 | Alto Frío | Vender arequipe donde está prohibido | 1 venta en la ciudad | Decomiso en un retén | Los dulces prohibidos |
| C8\_04 | El jefe de retén | Llevar un convoy de cuatro vehículos | Llegan al menos 3 | Llegan menos de 3 | El convoy completo |
| C8\_05 | Pan caliente | Dar el primer golpe a la Gran Panificadora | Vender panochas aún calientes | Capturan a toda la banda | El golpe semanal |
| C8\_06 | El primer vuelo | Detonante 7: aterrizar cargado con neblina | Aterrizaje con la carga entera | Se estrella o pierde la carga | Abre San Arequipe y las ciudades lejanas |

**Capítulo 9. El más buscado**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C9\_01 | Se busca | Quitar los carteles con tu cara antes de que amanezca | 10 carteles retirados | Amanece: empiezas el día con 2 estrellas | La fama como riesgo |
| C9\_02 | Redada en la casa grande | Evacuar o defender la mansión | Salvar el 70 % de lo guardado | Se pierde más del 30 % | Las redadas |
| C9\_03 | Brócoli | Primera captura obligada y fuga del internado | Fugarse por una de las tres rutas | La fuga falla: sube la condena | El internado |
| C9\_04 | La oferta de Don Mentol | Decidir si se le vende el negocio a medias | Tomar la decisión | No falla | Palabra y respeto; cambia el juego libre |
| C9\_05 | Todo listo | Preparar la gran persecución | 3 escondites puestos y 2 aliados avisados | No falla | La preparación de una prueba |
| C9\_06 | La gran persecución | Detonante 8: cruzar el valle con cinco estrellas | Llegar al hangar | Captura: se reinicia desde la preparación | Abre el renacimiento |

### Etapa 4: la leyenda

**Capítulo 10. La leyenda**

| ID | Misión | Qué hay que hacer | Se cumple cuando | Falla si | Enseña o desbloquea |
| --- | --- | --- | --- | --- | --- |
| C10\_01 | El heredero | Elegir quién sigue y qué recibe | Completar el primer renacimiento | No falla | El multiplicador permanente |
| C10\_02 | Ciudad nueva | Abrir mercado en la ciudad que trae el renacimiento | 5 ventas allá | Decomiso en ruta | Una ciudad por renacimiento |
| C10\_03 | El recetario perdido | Encontrar la primera página escondida en el valle | 1 página hallada | No falla | La búsqueda de recetas |
| C10\_04 | Lo que cuentan en la trocha | Vivir la primera leyenda del valle, de noche y en grupo | Terminar el evento | El grupo se dispersa | Las leyendas |
| C10\_05 | Sin final | Encargos generados por el propio valle | No se cierra nunca | No falla | El juego libre |

### Reparto del trabajo en misiones

| Quién | Qué hace |
| --- | --- |
| Santiago | Llena la ficha de cada misión: números, premios, textos y orden |
| Andrés | Crea los lugares, objetos y personajes que cada misión nombra |
| Pablo | Programa el sistema que lee las fichas y los 8 tipos de misión; los detonantes llevan código propio |

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

### Personajes, objetos y jefes

Ninguno es de una sola persona: cada uno tiene tres capas, y cada capa tiene su dueño. El orden de trabajo es siempre Santiago, luego Andrés, luego Pablo.

| Elemento | Santiago define | Andrés crea | Pablo programa |
| --- | --- | --- | --- |
| Personajes que hablan: Doña Melcocha, Don Ábaco | Qué dicen, qué encargos dan, qué premian | Aspecto, accesorios, animaciones | Diálogo en pantalla y entrega de encargos |
| Clientes y tenderos | Qué compran, cuánto pagan, cada cuánto | Aspecto y variaciones | Compra, demanda y aparición |
| Policía Dental | Cuántos salen por estrella, velocidad, alcance de visión | Agentes y patrullas | Patrullaje, persecución y captura |
| Trabajadores de banda y fincas | Costo, rendimiento, tareas | Aspecto | Rutas y trabajo automático |
| Objetos: dulces, armas, vehículos, utilería | Precio, efecto, tiempos, cuándo se abren | Modelo, efectos y sonido | Uso dentro del juego |
| Jefes: Comandante Muelas, La Chiclosa, Don Mentol | Vida, fases de la pelea, ataques, premio | Modelo, arena, animaciones y efectos | Comportamiento por fases y condiciones de victoria |

Si una capa falta, el elemento no entra al juego: un jefe sin números no se programa y uno sin modelo no se prueba.

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

## Guía de arte: cómo se ve todo

El juego se ve como una caricatura de barrio paisa: formas simples y redondeadas, colores vivos y planos, y cada cosa exagerada lo justo para reconocerla de lejos. Esta guía es la referencia de Andrés; los números son de partida.

### Reglas de estilo

- **Silueta primero.** Cada personaje y objeto se reconoce solo por su sombra: el Coordinador por la bata y el silbato, la patrulla por la muela en el techo.
- **Pocos polígonos, bordes suaves.** Nada de texturas realistas; el detalle se pinta con color.
- **Un color clave por cosa.** Lo que el jugador debe ver rápido lleva el color más fuerte de su zona.
- **Exageración cómica.** Cabezas, manos y objetos importantes un poco más grandes de lo real.
- **Nada da miedo.** No hay sangre, heridas ni armas de aspecto real; los golpes sueltan estrellas, confeti o muelitas.

### Paleta

| Uso | Color | Código |
| --- | --- | --- |
| Ladrillo a la vista | Rojo ladrillo | #B5533C |
| Teja de barro | Terracota | #A6452E |
| Fachadas | Amarillo, azul, rosado, verde menta y crema | #E8B33A, #3F8FC4, #E58FA6, #5FB7A0, #F1E3C2 |
| Calle y andén | Gris azulado y gris claro | #5B5F6B, #A9ABB3 |
| Monte y pasto | Verde montaña | #4E8B4A |
| Policía Dental | Blanco y verde menta | #F7F7F2, #7FD6C2 |
| Dinero y premios | Dorado | #F5C542 |
| Fama | Morado | #8E5BD6 |
| Peligro y alerta | Rojo sirena | #E5484D |

La Policía Dental y el internado son lo único blanco y frío del mapa; todo lo demás es cálido. Así el peligro se distingue de un vistazo.

### Personajes

| Personaje | Silueta | Ropa | Color clave | Rasgo cómico |
| --- | --- | --- | --- | --- |
| El jugador, de pelao | Bajito, morral más grande que la espalda | Uniforme con camisa por fuera y tenis | El que elija | El morral rebota al correr |
| El jugador, de muchacho | Más alto, casco en el brazo | Camiseta, jean y poncho al hombro | El que elija | Se acomoda el poncho antes de arrancar |
| El jugador, de don | Postura recta | Sombrero aguadeño, poncho, carriel y alpargatas | El que elija | El carriel tiene bolsillos que nunca se acaban |
| Doña Cocada, la mamá | Brazos en jarra | Delantal de flores y chanclas | Rosado | Olfatea el aire antes de hablar |
| Doña Melcocha, la abuela | Pequeña y redonda | Chal, moña blanca, cucharón de palo | Crema | Guiña el ojo cuando la mamá no mira |
| Coordinador Tiza | Alto, flaco, encorvado | Bata gris, silbato, planilla | Gris | Siempre tiene tiza en la manga |
| Agente de la Policía Dental | Cuadrado, casco redondo | Bata blanca, cinturón con cepillo y espejo | Verde menta | El casco tiene forma de muela |
| Comandante Muelas | Enorme, hombros anchos | Bata con charreteras, bigote | Blanco y dorado | Un diente de oro que brilla cuando sonríe |
| Tenderos | Barrigón tras el mostrador | Camisa de cuadros, lápiz en la oreja | Según la tienda | Cuentan con los dedos al regatear |
| La Chiclosa | Ágil, pelo en dos colas | Chaqueta rosada, patines | Rosado chicle | Infla una bomba antes de cada ataque |

### Prendas paisas

| Prenda | Cómo se ve | Qué hace en el juego |
| --- | --- | --- |
| Poncho | Tela blanca con rayas, doblado al hombro | Herramienta para llamar y manejar a los chivos |
| Carriel | Bolso de cuero con tapa peluda y muchos bolsillos | Es el inventario: cada mejora abre un bolsillo secreto |
| Sombrero aguadeño | Paja clara con cinta negra | Marca la etapa del don |
| Ruana | Lana gruesa oscura | Abrigo para la neblina de la trocha: se ve mejor |
| Alpargatas | Suela de fique | Pasos más silenciosos |
| Mulera | Paño al cuello | Cosmético de banda, con sus colores |

### Los dulces

| Dulce | Forma | Color | Tamaño | Envoltura |
| --- | --- | --- | --- | --- |
| Bombón | Esfera en palo | Rojo brillante | 1 stud | Papel transparente con moño |
| Chicle | Cubo | Rosado | 0,6 studs | Papel de dos colores |
| Gomita | Anillo | Verde, amarillo o rojo | 0,6 studs | Sin envoltura, con brillo de azúcar |
| Arequipe | Cajita redonda de madera con cuchara | Caramelo | 1 stud | Tapa de papel amarrada con cabuya |
| Panelita | Cuadrado plano | Café claro | 0,8 studs | Papel de seda blanco |
| Bocadillo | Bloque rectangular | Rojo oscuro | 1 stud | Hoja seca amarrada |
| Panocha | Pan redondo | Dorado con azúcar encima | 1,2 studs | Bandeja de panadería |

### Vehículos y objetos clave

| Objeto | Cómo se ve | Detalle que lo hace propio |
| --- | --- | --- |
| Bicicleta | Marco grueso, canasta de alambre adelante | Timbre y un parche en la llanta |
| Moto | Pequeña, de dos tiempos, con parrilla atrás | Echa humo azul al arrancar |
| Chiva o bus escalera | Bus de madera abierto, con bancas y parrilla en el techo | Pintado a mano con rombos y flores, cada uno distinto |
| Patrulla dental | Campero blanco y cuadrado | Sirena en forma de muela y parachoques de cepillo |
| Avioneta | Una hélice, alas altas | Amarilla, con un remolino de merengue en la cola |
| Teléfono público | Poste con caperuza metálica | Auricular negro con cable en espiral que se mece |
| Paradero | Techo de teja y banca de madera | Tablero pintado a mano, con las letras torcidas |
| Retén | Barrera roja y blanca, caseta y conos menta | El escudo es una muela con casco |
| Tienda de esquina | Reja, mostrador y frascos de vidrio | Aviso de gaseosa inventada y un cuaderno colgado de un clavo |

### Efectos visuales

| Efecto | Cuándo sale | Cómo se ve |
| --- | --- | --- |
| Monedas | Cada venta | Tres monedas doradas saltan del cliente al jugador |
| Aturdido | Golpe o cauchera | Muelitas girando sobre la cabeza |
| Crema | Pistola de crema | Mancha blanca que chorrea por el parabrisas |
| Confeti | Explosiones | Papelitos de colores y serpentinas que caen lento |
| Espuma | Granada de gaseosa | Burbujas que crecen y dejan charco pegajoso |
| Empalagado | Jugador vencido | Ojos en espiral y gotas de almíbar |
| Olor a dulce | Sospecha de la mamá | Ondas rosadas que salen del jugador o de la cocina |
| Estrella nueva | Sube la búsqueda | Una muela del marcador se enciende con destello rojo |
| Dulce dorado | Sorpresa de producción | Rayo de luz y chispas desde la olla |

## Guía de animación

Cada animación tiene nombre, duración, si se repite y el momento exacto en que se dispara, para que Andrés la anime y Pablo la conecte sin adivinar. Todas exageran el movimiento: se preparan antes del golpe y rebotan al terminar.

### El jugador

| Animación | Duración | Se repite | Qué se ve | Cuándo se dispara |
| --- | --- | --- | --- | --- |
| `Jugador_Reposo` | 3 s | Sí | Se balancea, mira a los lados y se acomoda el morral | Quieto |
| `Jugador_CaminarCarga` | 0,8 s | Sí | Inclinado hacia adelante, pasos cortos | Camina con carga |
| `Jugador_Huir` | 0,5 s | Sí | Corre con los brazos hacia atrás y el morral rebotando | Corre con una estrella o más |
| `Jugador_Vender` | 1,2 s | No | Saca el dulce, lo entrega con la palma abierta y lanza la moneda al aire | Venta cerrada |
| `Jugador_Ofrecer` | 1 s | No | Palma hacia arriba mostrando el dulce | Primer turno del regateo |
| `Jugador_Insistir` | 1 s | No | Señala el dulce y abre los brazos | Pide más en el regateo |
| `Jugador_CerrarTrato` | 1 s | No | Apretón de manos y cabezazo de aprobación | Regateo aceptado |
| `Jugador_Esconder` | 1 s | No | Mete todo al morral de un golpe y silba mirando al cielo | Guarda la carga con alguien cerca |
| `Jugador_Sigilo` | 1 s | Sí | Agachado, de puntillas | Modo sigilo |
| `Jugador_TocarPuerta` | 0,8 s | No | Tres golpes rápidos mirando hacia atrás | Pide escondite |
| `Jugador_Cauchera` | 0,6 s | No | Estira 0,3 s, suelta 0,1 s y retrocede 0,2 s | Dispara |
| `Jugador_PedalearSubida` | 0,7 s | Sí | De pie sobre los pedales, la bicicleta se mece | Bicicleta en pendiente |
| `Jugador_CargarCaja` | 0,9 s | No | Dobla rodillas, levanta y se tambalea | Recoge una caja |
| `Jugador_Celebrar` | 1,5 s | No | Salto con el puño arriba y dos pasos de parranda | Entrega perfecta o detonante superado |
| `Jugador_LimpiarAzucar` | 1 s | No | Se sacude la camisa y se huele la manga | Antes de entrar a la casa |
| `Jugador_Regano` | 2 s | Sí | Cabeza gacha, un pie dibuja círculos en el piso | Escena de regaño |
| `Jugador_Empalagado` | 2 s y bucle de 1,5 s | Sí | Cae sentado y queda mareado con la lengua afuera | Vencido |

### Policía Dental y Coordinador

| Animación | Duración | Se repite | Qué se ve | Cuándo se dispara |
| --- | --- | --- | --- | --- |
| `Agente_Patrullar` | 1 s | Sí | Camina tieso con las manos atrás | Ronda normal |
| `Agente_Revisar` | 2,5 s | No | Saca el espejo de dentista y lo mete por la ventana del vehículo | Revisión en retén |
| `Agente_Pitar` | 0,8 s | No | Se infla, pita y señala | Detecta al jugador |
| `Agente_Perseguir` | 0,5 s | Sí | Corre con la bata ondeando y el casco bailando | Persecución a pie |
| `Agente_Cegado` | 2 s | No | Se limpia la cara con las dos manos y da vueltas | Le cae crema |
| `Agente_Anotar` | 2 s | No | Lame el lápiz y escribe en la libreta | Decomiso o multa |
| `Agente_Volar` | 1,2 s | No | Sale por el aire sentado y cae rebotando | Cabezazo de chivo |
| `Agente_ComerEscondido` | 3 s | Sí | Mira a los lados y muerde un dulce detrás de la caseta | El agente a dieta, sin testigos |
| `Tiza_Ronda` | 1,2 s | Sí | Pasos largos, planilla contra el pecho | Ronda del colegio |
| `Tiza_OirBulla` | 0,6 s | No | Gira la cabeza de golpe con la oreja agrandada | Oye ruido |
| `Tiza_Confiscar` | 1,5 s | No | Estira la mano, guarda los dulces en el bolsillo y anota | Captura al jugador |

### Familia y vecinos

| Animación | Duración | Se repite | Qué se ve | Cuándo se dispara |
| --- | --- | --- | --- | --- |
| `Mama_Oler` | 1 s | No | Levanta la nariz y olfatea dos veces | El jugador entra con sospecha media |
| `Mama_Espera` | 2 s | Sí | Brazos cruzados y un pie golpeando el piso | Sospecha llena |
| `Mama_Cantaleta` | 3 s | Sí | Dedo acusador, mano en la cintura, niega con la cabeza | Escena de regaño |
| `Abuela_Guino` | 0,8 s | No | Guiña un ojo y esconde el cucharón | Cubre al jugador |
| `Tendero_Barrer` | 2 s | Sí | Barre el andén hacia la calle | Al abrir la tienda |
| `Tendero_Apuntar` | 1,5 s | No | Descuelga el cuaderno y anota | Fiado |
| `Tendero_Negar` | 1 s | No | Cruza los brazos y mira al techo | Rechaza en el regateo |
| `Tendero_Ceder` | 1 s | No | Suspira, alza los hombros y saca la plata | Acepta en el regateo |
| `Vecina_Balcon` | 4 s | Sí | Recostada en la baranda, comenta con la del frente | Ambiente del barrio |

### Reglas para conectarlas

- **Prioridad:** las de acción tapan a las de movimiento, y estas a las de reposo.
- **Lo que afecta el juego sale de la tabla de datos.** El aturdimiento dura lo que diga Santiago; la animación se ajusta a ese número y no al revés.
- **Toda acción tiene su sonido** en el mismo instante, según la guía de sonido.
- **Nombres exactos:** cada animación va al catálogo con el nombre de esta tabla.

## Guía de sonido

Cada cosa que pasa suena, y el sonido le dice al jugador qué tan bien o qué tan mal le fue sin mirar la pantalla. Los diálogos no llevan voces grabadas: los personajes hablan con un murmullo corto y cantadito, y el texto sale escrito.

### Sonidos del juego

| Momento | Sonido | Duración | Carácter |
| --- | --- | --- | --- |
| Venta | Moneda y caja registradora | 0,4 s | Brillante y corto |
| Venta triple | Lo mismo más una campanita | 0,7 s | Más agudo |
| Dulce dorado | Arpegio de tiple | 1 s | Único: no suena en nada más |
| Regateo que avanza | Cuenta de monedas | 0,5 s | Sube de tono si vas ganando |
| Tendero ofendido | Golpe en el mostrador | 0,4 s | Seco |
| Sospecha de la mamá sube | Olfateo | 0,6 s | Cómico |
| Regaño | Murmullo rápido que sube y baja | Bucle de 3 s | Cantaleta sin palabras |
| Pito del Coordinador | Silbato largo | 0,8 s | Agudo, se oye en todo el patio |
| Campana del colegio | Campana de mano | 2 s | Anuncia el recreo |
| Estrella nueva | Golpe grave y sirena corta | 0,8 s | Alarma |
| Sirena de patrulla | Dos notas agudas alternadas | Bucle | Ridícula, no amenazante |
| Cauchera | Estirón de caucho y chasquido | 0,5 s | Elástico |
| Pistola de crema | Chorro y salpicón | 0,6 s | Húmedo |
| Granada de gaseosa | Siseo y descorche | 1,2 s | Burbujeante |
| Dinamita de piñata | Estallido, confeti y pitos de fiesta | 1,5 s | Fiesta |
| Captura | Trombón que baja | 1,5 s | Derrota cómica |
| Escape logrado | Fanfarria corta de trompeta | 2 s | Triunfo |
| Teléfono público | Timbre mecánico doble | Bucle | Se oye a una cuadra |
| Radio | Estática y cortina de noticiero | 1 s | Antes de cada aviso |
| Bus escalera | Pito musical de varias notas | 1,5 s | Melodía propia de cada ruta |
| Bicicleta | Cadena, timbre y frenada | Según uso | Metálico |
| Moto | Motor de dos tiempos | Bucle | Sube de tono con la velocidad |

### Ambiente por hora

| Hora | Qué se oye |
| --- | --- |
| Mañana | Gallos, buses arrancando, escobas, una radio lejana |
| Mediodía | Niños en el recreo, vendedores, loza de almuerzo |
| Tarde | Truenos, aguacero sobre tejas, gente corriendo a escampar |
| Noche | Grillos, ranas, perros lejanos, parranda en alguna casa |
| Montaña | Viento, pájaros, quebrada, esquilas de animales |

### Música que sigue al peligro

La música se arma por capas según las estrellas, así que el jugador oye el peligro crecer.

| Estrellas | Capas que suenan |
| --- | --- |
| 0 | Guitarras suaves |
| 1 | Se suma la guacharaca |
| 2 | Se suma el tiple rápido |
| 3 | Entran las trompetas |
| 4 | Entran redoblante y platillos |
| 5 | Todo acelera y la sirena queda dentro del ritmo |

### Orden de volumen

1. Alertas: pito, estrella nueva, aviso de redada.
2. Respuesta a lo que hace el jugador: ventas, disparos, golpes.
3. Música.
4. Ambiente.

## El chivo y el poncho

Los chivos del valle no soportan el olor a menta de la Policía Dental, y el jugador puede aprovecharlo con el poncho para ganar segundos en una persecución. El chivo siempre gana: nunca sale lastimado, cae parado y se va trotando contento. Eso es parte del chiste y además lo exige Roblox, que no permite maltrato animal.

### Cómo es el chivo

- **Aspecto:** blanco con manchas café, cuernos cortos y curvos, barba, esquila al cuello y mirada de pocos amigos.
- **Dos tamaños:** el chivito, que se puede cargar, y el chivo grande, que solo se puede guiar.
- **Dónde hay:** en las veredas, en la trocha, en los solares de los barrios altos y cerca de los retenes de montaña. Entre 3 y 5 por zona.
- **Por su cuenta:** cada tanto, un chivo cercano a un retén embiste a un agente sin que nadie haga nada. Es ambiente, y abre una ventana para pasar.

### Los tres usos

| Uso | Cómo se hace | Qué pasa | Riesgo |
| --- | --- | --- | --- |
| Torear | Con el poncho puesto, se extiende a un lado cerca de un chivo | El chivo sigue el poncho hasta 15 segundos; si pasa junto a un agente, lo embiste | El chivo terco se sienta y no camina sin un dulce |
| Cargar | Solo con chivitos: se alza y aparece una barra de agarre | El jugador corre más lento mientras el chivito patalea | Si la barra se vacía, el chivito se suelta y embiste al jugador |
| Soltar | Se apunta hacia la policía y se suelta | El chivo cae parado, corre en línea recta y le da un cabezazo al primero que encuentre | Si falla, sigue de largo y se pierde el intento |

### Números de partida

| Dato | Valor |
| --- | --- |
| Tiempo máximo cargando un chivito | 6 segundos; hasta 10 con mejoras |
| Velocidad del jugador mientras carga | 20 % menos |
| Distancia de la embestida | 12 metros en línea recta |
| Agente golpeado | Sale volando y queda aturdido 4 segundos |
| Patrulla golpeada | Abollada y detenida 3 segundos |
| Jugador golpeado por su propio chivito | Tropieza 1 segundo |
| Descanso del chivo | Tras 2 embestidas, pasta 60 segundos y no hace caso |
| Espera entre usos | 30 segundos por jugador |

### Estados del chivo

1. **Pastando:** come, mueve la cola, suena la esquila.
2. **Curioso:** el jugador se acerca con el poncho; ladea la cabeza y mueve una oreja.
3. **Siguiendo:** trota detrás del poncho.
4. **Preparando:** huele menta, raspa el piso con una pata y baja la cabeza. Dura 0,6 segundos y es el aviso para el jugador.
5. **Embistiendo:** corre en línea recta.
6. **Contento:** tras el cabezazo, trota de lado dando saltitos y vuelve a pastar.
7. **Terco:** a veces se sienta mirando hacia otro lado, hasta que le dan un dulce.

### Animaciones y sonidos del chivo

| Animación | Duración | Se repite | Qué se ve | Sonido |
| --- | --- | --- | --- | --- |
| `Chivo_Pastar` | 3 s | Sí | Mastica y sacude la cola | Esquila suave |
| `Chivo_Curioso` | 1 s | No | Ladea la cabeza, una oreja se mueve | Balido corto de pregunta |
| `Chivo_Seguir` | 0,6 s | Sí | Trote corto con la cabeza en alto | Pezuñas y esquila |
| `Chivo_Raspar` | 0,6 s | No | Raspa el piso y baja los cuernos | Raspado y resoplido |
| `Chivo_Embestir` | 0,4 s | Sí | Carrera con la cabeza abajo y polvo detrás | Galope rápido |
| `Chivo_Cabezazo` | 0,3 s | No | Impacto y rebote hacia atrás | Golpe hueco y cómico |
| `Chivo_Contento` | 0,8 s | Sí | Saltitos de lado | Balido alegre |
| `Chivo_Patalear` | 0,5 s | Sí | Patas al aire en brazos del jugador | Balido de protesta |
| `Chivo_Terco` | 2 s | Sí | Sentado, mirando a otro lado | Resoplido |
| `Jugador_Torear` | 1 s | Sí | Poncho extendido a un lado, paso lateral | Tela al viento |
| `Jugador_CargarChivo` | 0,8 s | Sí | Corre tambaleándose con el chivito abrazado | Jadeo |
| `Jugador_SoltarChivo` | 0,7 s | No | Se agacha, lo pone en el piso y señala | Silbido |

### Otras ideas paisas y cómicas

| Idea | Qué pasa en el juego |
| --- | --- |
| La mula terca | Se atraviesa en la trocha y no se mueve. Con un pedazo de panela camina; pitándole, se sienta |
| El loro de Doña Rosalba | Si te escondes en esa casa, grita "¡dulces, dulces!". Se calla si le das una galleta antes |
| Las gallinas del solar | Al cruzar corriendo salen volando y hacen bulla: atraen agentes o sirven de distracción |
| La vaca en la vía | Frena el convoy. Hay que bajarse y arriarla, mientras el reloj corre |
| El arriero y su recua | Fila lenta de mulas en la montaña. Por un pago esconde tu carga entre los bultos |
| La silleta | Armazón a la espalda para cargar más a pie, más lento. Sirve en escaleras, donde no entra ningún vehículo |
| La aguapanela | Bebida que devuelve el aliento para correr y cargar |
| La parranda de la cuadra | Mientras suena la música en una casa, la policía no oye el motor de tu moto |
| El juego de rana | Minijuego en la tienda para ganar monedas y confianza del tendero |

## Sinergias: cómo reacciona el mundo entre sí

Ningún elemento funciona solo. La regla de diseño es que cada cosa nueva debe reaccionar con al menos otras dos que ya existan; así salen situaciones que nadie programó una por una.

| Esto | Con esto | Da |
| --- | --- | --- |
| Olor a menta de la policía | Chivo | Embestida |
| Poncho | Chivo | El jugador lo guía |
| Dulce | Perro callejero | Se vuelve amigo y les ladra a los agentes |
| Dulce | Chivo terco o mula | Vuelven a caminar |
| Olor a dulce | La mamá | Sube la sospecha |
| Olor a dulce | Perro | El perro te sigue y delata dónde te escondes |
| Bulla: balón, gallinas, pito | Coordinador o agente | Va a investigar y deja libre su puesto |
| Música de parranda | Motor de vehículo | No te oyen pasar |
| Crema | Parabrisas | Patrulla ciega 3 segundos |
| Crema | Lluvia | Se lava en 1 segundo |
| Lluvia | Trocha | Barro: los vehículos patinan y la carga puede caerse |
| Lluvia | Chivos y clientes | Se resguardan: menos ayuda y menos ventas en la calle |
| Neblina | Ruana | El jugador ve más lejos que los agentes |
| Espuma o confeti | Calle en bajada | Resbala todo el que pase, incluido el jugador |
| Noche | Faroles | Zonas de luz donde te ven y sombras para el sigilo |
| Radio | Operativo | Aviso 30 segundos antes |
| Fiesta de cuadra | Agentes | Se distraen comiendo y revisan menos |
| Alpargatas | Sigilo | Pasos que el Coordinador no oye |

### Qué hace cada uno en arte, animación y sonido

| Quién | Qué hace |
| --- | --- |
| Andrés | Modela según la guía de arte, anima cada fila de la guía de animación con su nombre exacto, y consigue o graba cada sonido de la guía de sonido |
| Santiago | Fija en la tabla de datos todo número que afecte el juego: aturdimientos, tiempos de carga, distancias, esperas y probabilidades |
| Pablo | Conecta animación y sonido a cada evento, programa los estados del chivo y la tabla de sinergias como reglas que leen etiquetas de cada objeto |

Para las sinergias, cada objeto lleva etiquetas como `HueleAMenta`, `HaceBulla` o `Resbala`, y el código reacciona a la etiqueta y no al objeto. Así una cosa nueva hereda las reacciones solo con ponerle la etiqueta.

Al lanzamiento entran las animaciones y sonidos de los capítulos 1 a 4. El chivo, la mula y las demás ideas de montaña llegan con las veredas, en la fase 7; si quieren al chivo antes, puede aparecer en los solares del barrio alto.

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
- [ ] Los tres ven el mensaje de prueba en Studio, cada uno en una copia local del lugar.
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
| 1. El recreo | 10 minutos |
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

## Producción por capítulo

Esta es la lista de todo lo que hay que crear, capítulo por capítulo, con la parte de cada uno. Los capítulos 1 a 4 son el lanzamiento y van al detalle; los capítulos 5 a 10 van resumidos y se detallan igual cuando llegue su fase.

### El paso a paso de cada elemento

Cada fila de las tablas sigue los mismos 6 pasos, sea un niño, un policía o una olla:

1. **Santiago** crea la fila en la tabla de datos con el identificador y sus números, y escribe en una frase qué hace el elemento.
2. **Andrés** lo modela o construye, lo importa a Studio con ese identificador exacto y agrega su fila al catálogo.
3. **Pablo** lo programa leyendo los números de la tabla y anota los eventos nuevos en la lista de eventos.
4. **El auditor** comprueba que el identificador coincide en los tres contratos.
5. **El dueño de cada capa** lo prueba dentro del juego y aprueba.
6. **El integrador** une los tres cambios y lo marca como hecho en el tablero.

### Capítulo 1. El recreo

| Elemento | Identificador | Santiago define | Andrés crea | Pablo programa |
| --- | --- | --- | --- | --- |
| Niños del colegio | `NPC_Estudiante` | Qué dulce pide cada uno, cuánto paga, cada cuánto vuelve a comprar | 3 variaciones con uniforme y morral | Aparecen en el patio, caminan y compran cuando te acercas |
| Coordinador | `NPC_Coordinador` | Alcance de visión, velocidad y cuántos dulces confisca | Modelo con silbato y planilla | Ronda por el patio, te detecta vendiendo y confisca |
| Doña Melcocha | `NPC_DonaMelcocha` | Textos del tutorial y primer encargo | Modelo con delantal y casa de la familia | Diálogo y guía paso a paso |
| Alcalde Apio | `NPC_AlcaldeApio` | Texto del anuncio que prohíbe el azúcar | Modelo y cartel de "Azúcar prohibida" | Escena de introducción |
| Dulces iniciales | `Dulce_Bombon`, `Dulce_Chicle`, `Dulce_Gomita` | Valor y tiempo de cada uno | Tres modelos | Objeto en inventario y venta |
| Morral | `Utileria_Morral` | Cuántos dulces carga | Modelo que se ve en la espalda | Inventario del jugador |
| Cauchera | `Arma_Cauchera` | Tiempo de aturdimiento y dulces por disparo | Modelo y efecto de impacto | Disparo y aturdimiento |
| Bicicleta | `Vehiculo_Bicicleta` | Velocidad y capacidad | Modelo con canasta y punto `Carga` | Conducción; se entrega al cerrar el capítulo |
| Colegio | `Mapa_Colegio` | Cuántos niños hay y horario del recreo | Patio, salones, portón y puntos de aparición | Hora del recreo y logro "Primer bombón" |

### Capítulo 2. La esquina

| Elemento | Identificador | Santiago define | Andrés crea | Pablo programa |
| --- | --- | --- | --- | --- |
| Don Ábaco | `NPC_DonAbaco` | Textos que explican la economía y sus encargos | Modelo con ábaco y su tienda | Diálogo y pantalla de mejoras |
| Tenderos | `NPC_Tendero` | Qué dulces compra cada tienda y a qué precio | 5 variaciones | Compra por demanda y trato de "tienda controlada" |
| Vecinos | `NPC_Vecino` | Cuántos circulan y qué tanto suben la demanda | 4 variaciones | Caminan por el barrio y entran a las tiendas |
| Tiendas | `Mapa_Tienda01` a `Mapa_Tienda06` | Demanda base y fama necesaria para controlarla | 6 fachadas con mostrador y letrero | Punto de venta, fama por tienda e ingreso pasivo |
| Caja de carga | `Utileria_CajaCarga` | Cuántos dulces lleva una caja | Modelo apilable | Cargar y descargar |
| Barrio | `Mapa_Barrio` | Distancias entre tiendas, que marcan el tiempo por entrega | Calles en ladera, casas y escaleras | Logro "Dueño de la cuadra" |

### Capítulo 3. La cocina de la abuela

| Elemento | Identificador | Santiago define | Andrés crea | Pablo programa |
| --- | --- | --- | --- | --- |
| Recetas caseras | `Dulce_Arequipe`, `Dulce_Panelita`, `Dulce_Bocadillo` | Valor, tiempo y costo de cada receta | Tres modelos | Producción con receta elegida |
| Olla y estufa | `Utileria_Olla`, `Utileria_Estufa` | Velocidad por nivel de mejora | Modelos con humo y burbujas | Estación de producción con temporizador |
| Mesa de empaque | `Utileria_MesaEmpaque` | Cuántos dulces se empacan por caja | Modelo | Pasar dulces a cajas |
| Cocina clandestina | `Mapa_Cocina` | Cuántas estaciones caben por nivel | Sótano de la casa con entrada escondida | Mejoras de cocina y producción en ausencia |
| Recetario | `Utileria_Recetario` | Orden en que se abren las recetas | Libro y su icono | Pantalla de recetas y logro "Receta secreta" |
| Moto | `Vehiculo_Moto` | Precio, velocidad y capacidad | Modelo con punto `Carga` | Conducción; se entrega al cerrar el capítulo |

### Capítulo 4. La ruta

| Elemento | Identificador | Santiago define | Andrés crea | Pablo programa |
| --- | --- | --- | --- | --- |
| Agentes de la Policía Dental | `NPC_AgenteDental` | Cuántos salen por estrella, velocidad y visión | Modelo con bata y cepillo | Patrullaje, persecución y captura |
| Patrulla | `Vehiculo_PatrullaDental` | Velocidad frente a la moto | Modelo con sirena en forma de muela | Persecución en carretera |
| Retenes | `Utileria_Reten` | Probabilidad de revisión según la carga | Barrera, conos y caseta | Inspección y confiscación |
| Estrellas de búsqueda | `Sistema_Estrellas` | Cuánto sube cada venta y cuánto tarda en bajar | Icono de estrella | Contador, subida y enfriamiento |
| Pistola de crema | `Arma_PistolaCrema` | Segundos que tapa el parabrisas y dulces por disparo | Modelo y efecto de crema | Disparo y ceguera de la patrulla |
| Maestro Tuerca | `NPC_MaestroTuerca` | Precios de mejoras de vehículo | Modelo y taller | Tienda de mejoras de vehículo |
| Escondites | `Utileria_Escondite` | Cuánto reducen la detección | Garajes y compartimientos | Ocultarse y bajar estrellas |
| Carreteras | `Mapa_Carretera01`, `Mapa_Carretera02` | Largo de cada ruta y número de retenes | Dos carreteras con 3 retenes | Logro "Ni una caries" |

### Capítulos 5 a 10, resumidos

| Capítulo | Personajes | Objetos | Mapa | Sistemas |
| --- | --- | --- | --- | --- |
| 5. La banda | Bombombún, repartidores, cocineros | Escopeta de chicle, mina de caramelo, camioneta, estantes de bodega | Bodega | Contratación, entregas automáticas, bandas, bodega común |
| 6. La guerra del azúcar | La Chiclosa como jefa, pandilla del chicle, Don Mentol | Granada de gaseosa, banderas de territorio, trampas | Tres barrios nuevos y la guarida del chicle | Territorios, defensa por oleadas, asalto de rutas, pelea con La Chiclosa |
| 7. La finca | Trabajadores, inspector sanitario | Bazuca de algodón, chiva, piezas de mansión y de parque | La Melcocha y El Ordeño | Fincas, cosecha diaria, inspecciones, decoración, visitas |
| 8. El puente aéreo | Capitán Merengue, compradores de otras ciudades | Avioneta, dinamita de piñata, cajas de exportación | La Molienda, El Guayabal, pista y tres ciudades | Vuelo, exportación, dulces legendarios |
| 9. El más buscado | Comandante Muelas como jefe final, Doctor Sarro, enfermeros, internos | Cañón de la chiva, patrulla blindada, cepillo gigante, bandeja de brócoli | Internado Sin Azúcar y ruta de la gran persecución | Cinco estrellas, pelea por fases, condena, fianza, fuga y rescate |
| 10. La leyenda | El heredero, Lola Paleta | Trofeo y cosméticos de renacimiento | Una ciudad nueva por renacimiento | Renacimiento, modo infinito, tabla global |

### Elementos que cruzan capítulos

| Elemento | Entra en | Santiago define | Andrés crea | Pablo programa |
| --- | --- | --- | --- | --- |
| Lola Paleta | Fase 3 | Lista de encargos diarios y premios | Modelo con libreta y puesto de periódico | Tres encargos diarios y titulares con tu nombre |
| Contrabandista | Fase 3 | Qué vende y cada cuánto rota | Modelo y carrito | Tienda rotativa cada 4 horas |
| Radio del vehículo | Después del lanzamiento | Qué emisoras se abren con qué fama | Música y carátulas de emisoras | Cambio de emisora al manejar |

## Dónde estamos y qué falta

El proyecto tiene el mapa de la primera región en bloques, la interfaz básica y el repositorio conectado; falta casi todo lo que hace que se pueda jugar. Este estado sale de las tres capturas del 16 de noviembre y de lo conversado, así que cada fila "por confirmar" la deben revisar ustedes dentro del juego.

| Parte | Estado | Qué se vio o qué falta |
| --- | --- | --- |
| Repositorio y Rojo | Hecho | La sesión `el-patron-del-dulce` aparece conectada en Studio |
| Mapa de la región 1 en bloques | Hecho | Zigzag con terrazas, dos barrios de edificios de colores, lomas y escaleras |
| Personaje jugable | Hecho | Camina por el mapa |
| Interfaz básica | Hecho, con un error | Pesos, fama, mejoras, cinco muelas, carga y avisos; un aviso tapa a otro |
| Cauchera | Por confirmar | Aparece en la barra; falta saber si dispara y aturde |
| Colegio | Por confirmar | No sé cuál edificio es ni si tiene interior, patio y portón |
| Casa y cocina | Por confirmar | Mencionadas junto al colegio; falta saber si tienen interior |
| Tiendas | Por confirmar | Los edificios están; falta saber si compran |
| Retenes | Por confirmar | Mencionados en el zigzag; no se ven funcionando |
| Producción, venta y mejoras | Por confirmar | El botón de mejoras existe; el dinero está en cero |
| Guardado de datos | Por confirmar | Sin evidencia |
| Contratos: tabla de datos, catálogo, eventos | Por confirmar | Sin evidencia |
| Personajes del mundo | Falta | No se ve ningún estudiante, tendero, Coordinador ni agente |
| Vehículos | Falta | No se ve bicicleta ni moto |
| Decoración de calle | Falta | Calles vacías: sin postes, cables, materas, avisos ni puestos |
| Montañas de fondo | Falta | El mapa termina en un borde plano |
| Sonido y música | Por confirmar | Sin evidencia |
| Edificio amarillo | Error | Se ve inclinado frente a los demás |

### El orden, paso a paso

Cada paso tiene una comprobación, y no se empieza el siguiente hasta que pase. Los pasos 5 a 11 son los capítulos 1 a 4, en orden.

| # | Paso | Quién | Está listo cuando |
| --- | --- | --- | --- |
| 1 | Revisar la tabla de estado y marcar cada "por confirmar" | Los tres | No queda ninguna fila sin respuesta |
| 2 | Corregir el edificio inclinado y los avisos montados | Andrés y Pablo | Las tres capturas repetidas ya no muestran los errores |
| 3 | Agrupar el mapa por zonas y nombrar cada pieza según el catálogo | Andrés | Ninguna pieza queda suelta ni con nombre genérico |
| 4 | Llenar los tres contratos con lo que ya existe | Cada dueño | El auditor no encuentra identificadores sin pareja |
| 5 | Primera venta: un estudiante compra y suben los pesos | Los tres | Un jugador nuevo vende sin que nadie le explique |
| 6 | Coordinador Tiza, sigilo y observador | Los tres | Lo atrapan si se descuida y escapa si se esconde |
| 7 | Casa, mamá, sospecha y regaño | Los tres | El regaño sale y el mandado se puede cumplir |
| 8 | Detonante 1 y portón | Los tres | Se pasa en menos de 5 intentos y se siente ganado |
| 9 | Tiendas, regateo y Don Ábaco | Los tres | El precio final cambia según cómo se regatea |
| 10 | Cocina, recetas y producción | Los tres | Un dulce sale al cumplirse su tiempo y se puede vender |
| 11 | Retenes, agentes, estrellas y la subida del zigzag | Los tres | Las cuatro salidas del retén funcionan |
| 12 | Decoración por cuadra, paraderos y placas de calles | Andrés | Cada cuadra cumple la receta de decoración |
| 13 | Sonido y música por capas | Andrés y Pablo | Con los ojos cerrados se sabe si subió una estrella |
| 14 | Guardado y rutina diaria | Pablo y Santiago | Salir y volver conserva todo, y la racha cuenta |
| 15 | Prueba con 5 jugadores nuevos | Santiago | La primera entrega toma menos de 2 minutos |
| 16 | Publicación | Los tres | Las tres firmas están dadas |

### Revisión del documento

Se corrigieron seis incoherencias entre secciones:

- El golpe a la panificadora decía abrirse en el capítulo 5, pero su misión está en el 8. Quedó en el capítulo 8.
- Las ciudades lejanas decían abrirse en el capítulo 10, pero se venden dulces allá desde el 8. Quedó en capítulos 8 y 10.
- La casa aparecía como "de la abuela" en dos tablas y como de la familia en el resto. Quedó como casa de la familia.
- El arranque pedía que los tres conectaran Rojo al mismo lugar, contra la regla de que solo Pablo sincroniza. Ahora cada uno prueba en una copia local.
- La meta de tiempo del capítulo 1 no coincidía con los primeros 10 minutos. Quedó en 10 minutos.
- Una fila de decoración tenía un texto de borrador. Se limpió.

Quedan cuatro decisiones abiertas:

- [ ] ¿Dónde está el colegio en el mapa actual? De eso depende ubicar zonas y retenes.
- [ ] ¿En qué anillo va el centro de Villa Almíbar? La tabla de anillos no lo incluye; lo lógico es el anillo 2.
- [ ] ¿El dulce del golpe es la panocha?
- [ ] Faltan los premios en pesos y fama de las 59 misiones y los textos de los diálogos.

Esta revisión se hizo contra lo escrito en cada sección al crearla, no releyendo el documento línea por línea, y no cubre el juego en sí.

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
