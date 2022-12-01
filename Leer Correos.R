#--------------------------------------------------------
#
#       Proyecto numero 1 de crecimiento profesional
#
#--------------------------------------------------------

#------------------------------------------------------ 
# La idea de este proyecto es crear un script que se meta en Gmail y extraiga 
# la informacion de los gastos basados en las notificaciones de Gmail.
#
# Que funcione para diferentes bancos y crear reportes de gastos por tipos/meses
#------------------------------------------------------


#----------------------------------
#     Environment
#----------------------------------

# Working directory
setwd("D:/Proyects/Proyecto #1 - Email Notification Reading")

# Libraries
library(gmailr) # https://gmailr.r-lib.org/reference/gm_messages.html
library(googlesheets4)
library(tidyverse)
library(base64url)
library(fuzzyjoin)
library(lubridate)
library(RColorBrewer)


#----------------------------------
#     Authentication
#----------------------------------

# auto auth
# gs4_auth("luis.vasquezellis@gmail.com") # This is for G.Sheets writing

# https://developers.google.com/gmail/api/guides
gm_auth_configure(path = "client_secret.json")
options(
  gargle_oauth_cache = ".secret",
  gargle_oauth_email = "luis.vasquezellis@gmail.com"
)

#----------------------------------
#     Reading the emails
#----------------------------------

# use_secret_file("client_secret.json")
# lookup all the messages
a <- gm_messages("Notificación de Consumo",
                 include_spam_trash = FALSE,
                 num_results= 500)




#----------------------------------
#     Processing the emails
#----------------------------------

# Useful links used
#never mind, I solved it on R
# https://stackoverflow.com/questions/65885152/how-can-i-get-the-body-of-a-gmail-email-with-an-attatchment-gmail-python-api 
# Solution to the body thing in python
# https://stackoverflow.com/questions/73674782/gmail-api-get-full-body-text
# https://developers.google.com/gmail/api/reference/rest/v1/users.messages.attachments#MessagePartBody


# Valores relevantes - vacios dataset
Id_correo = c()
Fecha_correo = c()
# body = c()
Texto_fuente = c()
Tarjeta = c()
Monto_string = c()
Moneda = c()
Monto = c()
Fecha = c()
Descripcion = c()
Estatus = c()



for (i in 1:length(a)) {
  for(j in 1:length(a[[i]][["messages"]])) {
    
    # Check mail ID
    Id_correo = c(Id_correo,a[[i]][["messages"]][[j]][["id"]])
    print(a[[i]][["messages"]][[j]][["id"]])
    
    # Read the email
    Email = gm_message(a[[i]][["messages"]][[j]][["id"]])
    
    # Structure of mail
    Fecha_correo = c(Fecha_correo,Email[["payload"]][["headers"]][[22]][["value"]])
    body = Email[["payload"]][["parts"]][[1]][["body"]][["data"]]
    
    # Extraction of relevant parts of mail -
    texto = base64_urldecode(body)
    
    Tarjeta_tmp = str_extract(texto,regex("(Tarjeta|VISA|MASTERCARD).*(?=, terminada)"))
    
    
    Monto_string_tmp =str_replace_all(
      str_extract(texto,
                  regex("(?<=Estatus).* \\t(?=[:digit:])",dotall = T)
      )
      ,pattern = regex("\\t|\\r|\\n"),replacement = "")
    
    Moneda_tmp = str_extract(Monto_string_tmp,regex("RD|US"))
    Monto_tmp = str_replace(str_trim(str_replace(str_extract(Monto_string_tmp,regex("(?<=RD|US).*")),"\\$","")),",","")
    Fecha_tmp = str_trim(str_extract(texto,regex("[:digit:]*/[:digit:]*/[:digit:]* ")))# asumir la del correo?
    Descripcion_tmp =  str_trim(
      str_extract(
        str_remove_all(texto,"[\r\n\t]"),
        regex("(?<=[:digit:]{2}/[:digit:]{2}/[:digit:]{4}).*(?=Aprobada|Declinada|Fondos Insuficientes)"))
    )
    Estatus_tmp = str_extract(texto,regex("Aprobada|Declinada|Fondos Insuficientes"))
    
    # crear vector
    
    Texto_fuente = c(Texto_fuente,texto)
    Tarjeta = c(Tarjeta,Tarjeta_tmp)
    Monto_string = c(Monto_string,Monto_string_tmp)
    Moneda = c(Moneda,Moneda_tmp)
    Monto = c(Monto,Monto_tmp)
    Fecha = c(Fecha,Fecha_tmp)
    Descripcion = c(Descripcion,Descripcion_tmp)
    Estatus = c(Estatus,Estatus_tmp)
  }
}

# Eliminar temps
rm(i,j,body,Descripcion_tmp,Fecha_tmp,Moneda_tmp,Monto_string_tmp,Monto_tmp,
   Tarjeta_tmp,texto,Estatus_tmp,Email)

# Crear Tabla

transacciones = tibble(
  Id_mail = Id_correo,
  Fecha_correo = Fecha_correo,
  Texto_fuente = Texto_fuente,
  Tarjeta = Tarjeta,
  Monto_string = Monto_string,
  Moneda = Moneda,
  Monto = Monto,
  Fecha = Fecha,
  Descripcion = Descripcion,
  Estatus = Estatus
) 

# Limpiar monto rapidamente
transacciones$Monto =  str_split(transacciones$Monto," ", simplify = T)[,1]




# Limpiar espacio de trabajo
rm(Id_correo,Fecha_correo,Texto_fuente,Tarjeta,Monto_string,Moneda,Monto,
   Fecha,Descripcion,Estatus)


# Al estar seguros elimnamos los emails
flag = 1
if (flag) {
  rm(a)
  
}

rm(flag)
#----------------------------------
#     Improving our dataset
#----------------------------------

# I will use fuzzy match with a catalog of things I know I want to categorise, 
# There will be 2 levels:
# General Description -
#         Where we can see the detail of the expense, Claro, Didi, PedidosYa, etc
# Group of Expense
#         Where we group those on the General Description: Monthly Bills, Food, Leisure, etc

Catalogo_gastos = tibble(
  Matching = c("CLARO PAGO","CLARO RECAR","MI CLARORE","UBER TRIP","Spotify",
               "PAYPAL","EDEESTE","CAASD","ESSO","DONG","NEXT",
               "OFI","OF.","PEDIDOS YA","Didi","BRAVO",
               "JUMBO","PRICE SMART","GOOGLE","ANAKY","ARANTXA NATURAL",
               "LA SIRENA","AMZN","FARMACIA","LAVATEX","CEDIMAT","CAMPUNO",
               "EATSPENDING","MCDONALD","PAYPAL *CHESSCOM","KRISPY",
               "WENDYS","STARBUCKS","TACO BELL","SUPERCHURROS","TRUCK",
               "DOMEX","BURGER KING","Dominos Pizza","LICORSTORE",
               "AERODOM AILA","MEGA DRINK","CENTRO POLICLINICO","BOCAO","BEERS AND CO",
               "CAPITALBREWHOUSE","FORNO BRAVO","GREEN BOWL",
               "HELADOS BON","HUMMUS","JADE TERIYAKI","KACHAO","KFC",
               "LA LOCANDA","LAUREL","LITTLE CAESARS","WALLI S BURGER",
               "VINOABEBER","STOLI"),
  Detalle_Gasto = c("Claro","Claro","Claro","Uber","Spotify",
                    "Paypal","Edeeste","CAASD","Bomba","Dong Chinese","Bomba",
                    "Retiro Cajero","Retiro Cajero","Pedidos Ya","Didi","Bravo",
                    "Jumbo","Price smart","Google Play","Carro","Salon",
                    "La Sirena","Amazon","Farmacia","Lavanderia","Medico",
                    "Restaurantes Varios","Uber Eats","Comida Rapida",
                    "Ajedrez","Comida Rapida","Comida Rapida","Cafe",
                    "Comida Rapida","Comida Rapida","FoodTrucks",
                    "Domex","Comida Rapida","Comida Rapida","Bebidas Alcoholicas",
                    "Parqueo Aeropuerto","Bebidas Alcoholicas","Medico","Bocao",
                    "Bebidas Alcoholicas","Bebidas Alcoholicas","Restaurante",
                    "Comida Rapida","Helado","Comida Rapida","Comida Rapida",
                    "Restaurante","Comida Rapida","Restaurante","Restaurante",
                    "Comida Rapida","FoodTrucks","Bebidas Alcoholicas",
                    "Bebidas Alcoholicas"),
  Grupo_Gasto = c("Gastos Mensuales","Gasto Recargas","Gasto Recargas",
                  "Uber","Subscripciones Mensuales",
                  "Gastos Paypal","Gastos Mensuales","Gastos Mensuales",
                  "Gasolina","Subscripciones Mensuales","Gasolina",
                  "Efectivo","Efectivo", "Comida","Comida","Supermercado",
                  "Supermercado","Supermercado","Gaming","Gastos Vehiculo","Salon",
                  "Supermercado","Gastos Amazon","Farmacia","Lavanderia","Salud",
                  "Comida","Comida","Comida","Subscripciones Mensuales", "Comida",
                  "Comida","Comida","Comida","Comida","Comida","Gastos Amazon",
                  "Comida", "Comida","Bebidas Alcoholicas","Otros Gastos",
                  "Bebidas Alcoholicas","Salud","Boletas/Festivales",
                  "Boletas/Festivales","Boletas/Festivales","Comida",
                  "Comida","Comida","Comida","Comida","Comida","Comida",
                  "Comida","Comida","Comida","Comida","Boletas/Festivales",
                  "Boletas/Festivales")
) %>% 
  filter(!Matching %in% c("TRUCK")) # Eliminar los que no funcionan

#Fuzzy Match by descriptions

transacciones_catalogo = transacciones %>% 
  stringdist_left_join(Catalogo_gastos,
                       by = c("Descripcion" = "Matching"),
                       method = "jw",
                       distance_col = "dist",
                       max_dist = 0.30) %>% 
  group_by(Id_mail) %>% 
  arrange(desc(dist)) %>% 
  filter(row_number() == 1) %>% # Filter works better than slice_min because I want to keep
                                # rows that didn't match for some hard-coding
  mutate(Grupo_Gasto = if_else(!is.na(Grupo_Gasto),Grupo_Gasto,"Otros"),
         Detalle_Gasto = if_else(!is.na(Grupo_Gasto),Grupo_Gasto,"Otros")) %>% 
  select(-dist,-Matching)
# %>% 
#   slice_min(order_by = dist, n=1,)

# The last thing we have to do for this data to be ready is change USD to DOP

transacciones_catalogo = transacciones_catalogo %>% 
  mutate(Monto = if_else(Moneda == "RD",as.numeric(Monto),as.numeric(Monto)*52),
         Fecha = dmy(Fecha))


# clean space
# rm(transacciones,Catalogo_gastos) # will keep in case I need to change more things

#----------------------------------
#     Crunch our numbers
#----------------------------------

# Let's explore our spending habits

# Get colors for graph
mycolors = colorRampPalette(
  brewer.pal(8, "Set2"))(length(unique(transacciones_catalogo$Grupo_Gasto)))

# Process the data and then graph
transacciones_catalogo %>% 
  filter(Estatus == "Aprobada",
         Fecha >= as.Date("2022-01-01")) %>% 
ggplot(aes(x=as.factor(month(Fecha)), y= Monto, fill=Grupo_Gasto)) +
  geom_col() +
  xlab("Mes") +
  ylab("Gasto Total") +
  ggtitle("Gastos 2022 por Grupo de Gasto") +
  scale_fill_manual(values = mycolors)
# November is an outlier in expenses 
# (I know exactly why but this is the interesting part about data)

# We can do many 

#----------------------------------
#     Exploration part - safekeeping
#----------------------------------


# Ejemplos: 1849ae06b4e2363e
length(a)
a[[1]][["messages"]][[1]][["id"]]
Id_mail = "1849ae06b4e2363e"

# Read the email
Email = gm_message(Id_mail)

Fecha_correo = Email[["payload"]][["headers"]][[22]][["value"]]
body = Email[["payload"]][["parts"]][[1]][["body"]][["data"]]

texto = base64_urldecode(body)
texto

# Problema encontrado en 11/29 9 a.m descripcion fallando
# Version inicial descripcion:
Descripcion =  str_replace(str_extract(texto,regex("(?<=/[:digit:]{4} \\t).*(?=\\r=)")),
                           pattern = "Aprobada|Declinada|Fondos Insuficientes","")


# Modificacion Descripcion:
Descripcion_prueba =  str_trim(
  str_extract(
    str_remove_all(texto,"[\r\n\t]"),
    regex("(?<=[:digit:]{2}/[:digit:]{2}/[:digit:]{4}).*(?=Aprobada|Declinada|Fondos Insuficientes)"))
)

# No funciona con algunas, ya vemos:
Descripcion_prueba =  str_replace_all(
  str_extract(
    transacciones$Texto_fuente[1],
    regex("(?<=[:digit:]{2}/[:digit:]{2}/[:digit:]{4}).*(?=Aprobada|Declinada|Fondos Insuficientes)")),
  pattern = "\t","")

str_extract(
  str_remove_all(transacciones$Texto_fuente[1],"[\r\n\t]"),
  regex("(?<=[:digit:]{2}/[:digit:]{2}/[:digit:]{4}).*(?=Aprobada|Declinada|Fondos Insuficientes)"))

Tarjeta = str_extract(texto,regex("(Tarjeta|VISA|MASTERCARD).*(?=, terminada)"))


Monto_string=str_replace_all(
  str_extract(texto,
              regex("(?<=Estatus).* \\t(?=[:digit:])",dotall = T)
              )
  ,pattern = regex("\\t|\\r|\\n"),replacement = "")

Moneda = str_extract(Monto_string,regex("RD|US"))
Monto = str_replace(str_trim(str_replace(str_extract(Monto_string,regex("(?<=RD|US).*")),"\\$","")),",","")
Fecha= str_trim(str_extract(texto,regex("[:digit:]*/[:digit:]*/[:digit:]* ")))# asumir la del correo?

Estatus = str_extract(texto,regex("Aprobada|Declinada|Fondos Insuficientes"))



# This is what I need to keep q
# Email[["snippet"]]
# Email[["internalDate"]]


