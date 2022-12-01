# Proyecto # 1 de Proyeccion Profesional: Email Notification Reading

Este es un proyecto que tengo años queriendo hacer, la verdad que me tomó mucho tiempo tomar acción pero hoy lo comienzo a hacer realidad.

## Background

Yo siempre he sido muy apasionado por mis finanzas personales y siempre las he traqueado pero de formas muy manuales debido a que los bancos de Republica Dominicana no te dejan ser muy creativo, entonces como solución había pensado en crear un algoritmo que entrara al Gmail y leyera las notificaciones de los bancos y las cargara a un sheet o algún sitio para analisis futuro.

* Lo hare en R porque es el lenguaje de programacion que me siento comodo, a lo mejor en un futuro lo traduzco a Python.

Aqui pegare como tenia pensado como hacer este proyecto(las fases):

1) Crear script que se conecte a Gmail
	- crear API conection con el mail
2) Query los correos por combinaciones (BPD,APAP,BHD)
	- Separar como sea necesario
3) Cuando el query arroje los resultados deseados entonces tomar uno o dos ejemplos, para crear el proceso de leer y asignar en un dataframe o lista
4) Luego que el proceso este creado, vectorizar este proceso para que loopee por los resultados ya obtenidos
5) Verificar los resultados con los diferentes querys en DFs o listas
6) Crear catalogo de: Tipo de gastos, Monedas y demas catalogos necesarios.
7) Combinar los catalogos y la data
8) Crear un dataset maestro para G. Sheets o PBI
9) Diseñar lindo reporte para poner como resultado final 

## Implementation

Para este punto de carga del proyecto solamente faltan los puntos 8 y 9, los demas puntos quedan por mejorar, el punto B solamente se hace para BPD pero queda pendiente hacer el desarollo para los otros dos bancos que uso de vez en cuando (APAP lo utilizo mas frecuente).


## Notas:

Cada uno de los proyectos que comenzaré a colgar en mi GitHub serán lanzados y luego retocados cada 3 proyectos más o menos, por ejemplo este lo he cargado hoy Primero de Diciembre del 2022, le haré unos cambios durante lo que queda la primera semana de Diciembre y será retocado en Febrero cuando ya haya cargado el Proyecto Numero 2 y 3; en ese mismo mes haría revisión de estos 2 proyectos tambien.


Con este Commit se despide su servidor,

Luis Vasquez Ellis.
