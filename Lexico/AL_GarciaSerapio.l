%{
/* 
Elaborar un alizador lexico en lex/flex que reconozca los componentes lexicos pertenecientes a las
clases abajo descritas

Elaborador por:
- Garcia Lopez Erik
- Serapio Hernandez Alexis Arturo

Fecha de elaboracion: 03/10/2023

Clase   |   Descripcion
0       |   Operadores aritmeticos
1       |   Operadores logicos
2       |   Operadores relacionales
3       |   Constantes numericas enteras
4       |   Palabras reservadas
5       |   Identificadores
6       |   Simbolos especiales
7       |   Operadores de asignacion
8       |   Constantes cadenas
9       |   Operadores sobre cadenas

*/
#include <stdlib.h>
#include <stdio.h>
#include <string.h>


FILE *archSal;  //Archivo para la salida
FILE *tokens;   //Archivo para los tokens

int im = 0;   //Bandera auxiliar en la tabla de simbolos
int im1 = 0;  //Bandera auxiliar en la tabla de literales para cadenas
int im2 = 0; 

int n = 0;

//Estructura para los nodos. Tiene valor y clase
typedef struct nodo{
    int valor;
    char *clase;
    struct nodo *siguiente;
}Nodo;

//Estructura para manejar a los identificadores como simbolos para ingresarlos en la tabla de simbolos
struct Iden{
    struct Iden *next;
    int posicion;
    char nombre[63];
    int tipo;
};

//Estructura para la lista de simbolos y tener almacenados todos los identificadores
struct ListaS{
    struct Iden *raiz;
    int total;
    struct Iden *ultimo;
};

//Estructura para almacenar listas de cualquier tipo, se tiene un nodo apuntador raiz , entero y nodo apuntador ultimo
typedef struct lista{
    Nodo *raiz;
    int total;
    Nodo *ultimo;
}Lista;

//Estructura para manejar a las constantes cadenas para ingresarlos en la tabla de literales
struct nodoCadena{
    int valor;
    char clase[80];
    struct nodoCadena *siguiente;
};

//Estructura que sirve como lista para manejar constantes
struct listaC{
    struct nodoCadena *raiz;
    int total;
    struct nodoCadena *ultimo;
};



//Funcion tipo lista que retorna una nueva lista creada con valores null
Lista *crearLista(){
    Lista *l = (Lista*)malloc(sizeof(Lista));
    l->raiz = NULL;
    l->total = 0;
    l->ultimo = NULL;
    return l;
}

//Verifica si una lista existe, si existe regresa 1 y si no existe regresa 0
int isVacia(Lista *l){
    if(l->raiz == NULL)
        return 1;
    else
        return 0;
}

//Funcion para insertar elementos en una lista
//Recibe una lista y el nodo(valor y clase)
void insertar(Lista *l, Nodo *n){
    if(isVacia(l)){
        l->raiz = n;
        l-> ultimo= n;
    }else{
        l->ultimo->siguiente = n;
        l->ultimo = n;
    }
    l->total++;
}

//Funcion de tipo nodo, recibe valor y clase
//Crea un nodo para cadenas
Nodo *crearNodo(int valor, char *clase){
    Nodo *n = (Nodo*)malloc(sizeof(Nodo));
    n->valor = valor;
    n->clase = clase;
    n ->siguiente = NULL;
    return n;
}

//Recibe como parametro un nodo e imprime su valor y clase
void imprimirNodo(Nodo *n){
    printf("%d %s\n",n->valor, n->clase);
}

//Imprime los nodos que encuentra en una lista
void printLista(Lista *l){
    Nodo *aux=l->raiz;
    while (aux != NULL){
        imprimirNodo(aux);
        aux = aux ->siguiente;
    }
}

//Devuelve un entero correspondiente a la posicion del operador logico en el catalogo
//Recibe como parametro una cadena que es el operador logico identificado en la ER
//Si no enceuntra ninguna coincidencia devuelve -1
int opLogicos(char *opl){

    if (!strcmp(opl,"&&")){
        return 0;
    } else if (!strcmp(opl,"||")){
        return 1;
    } else if (!strcmp(opl,"!")){
        return 2;
    } else {
        return -1;
    }

}

//Devuelve un entero correspondiente a la posicion del operador relacional en el catalogo
//Recibe como parametro una cadena que es el operador relacional identificado en la ER
//Si no enceuntra ninguna coincidencia devuelve -1
int opRelacionales(char *opr){

    if (!strcmp(opr,"==")){
        return 0;
    } else if (!strcmp(opr,"!=")){
        return 1;
    } else if (!strcmp(opr,">")){
        return 2;
    } else if (!strcmp(opr,"<")){
        return 3;
    } else if (!strcmp(opr,">=")){
        return 4;
    } else if (!strcmp(opr,"<=")){
        return 5;
    } else {
        return -1;
    }

}

//Funcion que recibe una cadena de caracteres y se encarga de quitar parentesis si es que los tiene
//De igual forma quita el simbolo '+''
//Regresa la cadena con sus respectivos cambios
char* cteNumerica(char* cadena) {
    char* inicioParentesis = strchr(cadena, '(');
    
    if (inicioParentesis != NULL) {
        char* finParentesis = strchr(inicioParentesis, ')');
        
        if (finParentesis != NULL) {
            size_t longitud = finParentesis - inicioParentesis;
            
            char* nuevaCadena = (char*)malloc(longitud);
            
            if (nuevaCadena != NULL) {
                strncpy(nuevaCadena, inicioParentesis + 1, longitud - 1);
                nuevaCadena[longitud - 1] = '\0'; // Añade el simbolo de fin de cadena
                
                // Elimina el +
                char* simboloPlus = strchr(nuevaCadena, '+');
                if (simboloPlus != NULL) {
                    memmove(simboloPlus, simboloPlus + 1, strlen(simboloPlus));
                }
                
                return nuevaCadena;
            }
        }
    }
    
    // Si no se encontraron paréntesis o hubo algun error retorna la cadena original
    return cadena;
}

//Devuelve un entero correspondiente a la posicion de la palabra reservada en el catalogo
//Recibe como parametro una cadena que es la palabra reservada identificada en la ER
//Si no enceuntra ninguna coincidencia devuelve -1
int palReservada(char *pal){
    if (!strcmp(pal,"assinado")){
        return 0;
    } else if (!strcmp(pal,"caso")){
        return 1;
    } else if (!strcmp(pal,"enquanto")){
        return 2;
    } else if (!strcmp(pal,"fazer")){
        return 3;
    } else if (!strcmp(pal,"flutuador")){
        return 4;
    } else if (!strcmp(pal,"inteiro")){
        return 5;
    } else if (!strcmp(pal,"para")){
        return 6;
    } else if (!strcmp(pal,"quebrar")){
        return 7;
    } else if (!strcmp(pal,"retorno")){
        return 8;
    } else if (!strcmp(pal,"se")){
        return 9;
    } else if (!strcmp(pal,"trocar")){
        return 10;
    } else {
        return -1;
    }
}

//Estructura para tener una lista global de simbolos donde se pueda ir verificando su existencia y/o agregar mas simbolos
struct ListaS Simbolos;

// Recorre la lista ligada y regresa la posición de ocurrencia.
// Si no hay coincidencias regresa el valor -2.
int buscarenTS( char *ide){
    struct Iden *a = Simbolos.raiz;
    while (a!=NULL) {
        if(!strcmp(ide, a->nombre)){
            return a->posicion;
            }
            a = a->next;
            };
            return -2;
}

//Funcion que toma un identificador como entrada y lo agrega a la tabla de símbolos si es la primera
//vez que se encuentra. Si el identificador ya existe en la tabla de símbolos, se recupera su posición.
//Regresa 02 su no se encuentra en la tabla
int TablaSimbolos(char *identifi){
    int p =0;  //posicion
    if(im==0){ //Si es la primera vez que se llama a esta funcion se crea un nuevo identificador y se agrega a la tabla de simbolos
        struct Iden *iden0;
        iden0 = (struct Iden*)malloc(sizeof(struct Iden));
        iden0->next = NULL,
        iden0->posicion = Simbolos.total;
        strcpy(iden0->nombre, identifi);
        iden0->tipo = -1;
        Simbolos.raiz = iden0;
        Simbolos.ultimo = iden0;
        p = Simbolos.total;
        Simbolos.total++;
        im++;
        }
        else{ //Si no es la primera vez lo busca en la TS. Regresa -2 si no se enceuntra en la tabla, se crea un nuevo identificador y se agrega a la tabla
            p=buscarenTS(identifi);
                if(p==-2){
                    struct Iden *iden1;
                    iden1 = (struct Iden*)malloc(sizeof(struct Iden));
                    iden1->next = NULL;
                    iden1->posicion = Simbolos.total;
                    strcpy(iden1->nombre, identifi);
                    iden1->tipo = -1;
                    Simbolos.ultimo->next = iden1;
                    Simbolos.ultimo = iden1;
                    p=Simbolos.total;
                    Simbolos.total++;
                    im++;
                }
            }
                return p; //Devuelve la posicion del identificador en la tabla de simbolos
}


//Devuelve un entero correspondiente a la posicion del operador de asignacion en el catalogo
//Recibe como parametro una cadena que es el operador de asignacion identificado en la ER
//Si no enceuntra ninguna coincidencia devuelve -1
int opAsignacion(char *opa){

    if (!strcmp(opa,"=")){
        return 0;
    } else if (!strcmp(opa,"+=")){
        return 1;
    } else if (!strcmp(opa,"-=")){
        return 2;
    }  else {
        return -1;
    }

}

//Lista con el nodo que almacena cadenas.
struct listaC Cadenas;

// Devuelve un entero que es la posicion de la cadena que esta en la tabla de literales de cadenas
// Recibe como parametro la cadena identificada por la ER
int constantescadena(char *cadena){
    int p =0;  //posicion
    if(im1==0){  //Si es la primera vez que se ejecuta esta funcion
        struct nodoCadena *iden0;
        iden0 = (struct nodoCadena*)malloc(sizeof(struct nodoCadena));
        iden0->siguiente = NULL,
        iden0->valor = Cadenas.total;
        strcpy(iden0->clase, cadena);
        Cadenas.raiz = iden0;
        Cadenas.ultimo = iden0;
        p = Cadenas.total;
        Cadenas.total++;
        im1++;
    } else{  //Si no es la primera vez que se ejecuta esta funcion
        struct nodoCadena *iden1;
        iden1 = (struct nodoCadena*)malloc(sizeof(struct nodoCadena));
        iden1->siguiente = NULL;
        iden1->valor = Cadenas.total;
        strcpy(iden1->clase, cadena);
        Cadenas.ultimo->siguiente = iden1;
        Cadenas.ultimo = iden1;
        p=Cadenas.total;
        Cadenas.total++;
        }
        return p;  //Regresa la posicion p
}



//Devuelve un entero correspondiente a la posicion del operador sobre cadenas en el catalogo
//Recibe como parametro una cadena que es el operador sobre cadenas identificado en la ER
//Si no enceuntra ninguna coincidencia devuelve -1
int opCadena(char *opc){

    if (!strcmp(opc,"&")){
        return 0;
    } else if (!strcmp(opc,"like")){
        return 1;
    } else {
        return -1;
    }

}

//Imprime posicion, nombre y tipo del simbolo
//Recibe como parametro un nodo donde se guarda la informacion
void imprimirSimbolo(struct Iden *ss){
    printf("%d %s %d\n", ss->posicion, ss->nombre, ss->tipo);
}

//Imprime el nodo de cadenas donde se enceuntre la ejecucion del programa
//Devuelve el valor y la clase
void imprimirNodoCadena(struct nodoCadena *nc){
    printf("%d %s\n", nc->valor, nc->clase);
}

//Imprime la tabla de simbolos en forma de lista
//Recibe como parametro una lista, donde se almacenan los identificadores
void imprimirS(struct ListaS *ls){
    struct Iden *aux = ls->raiz;
    while(aux != NULL){
        imprimirSimbolo(aux);
        aux = aux->next;
    }
}

//Imprime la tabla de literales en forma de lista
//Recibe como parametro una lista, donde se almacenan las cadenas
void imprimirC(struct listaC *lc){
    struct nodoCadena *aux = lc->raiz;
    while(aux != NULL){
        imprimirNodoCadena(aux);
        aux = aux->siguiente;
    }
}

//Imprime en pantalla la tabla de simbolos y la tabla de cadenas
void mostrarTablas(){
    printf("\n");
    printf("Tabla de simbolos: \n");
    printf("Posicion|Nombre|Tipo\n");
    imprimirS(&Simbolos);

    printf("\n");
    printf("Tabla de literales: \n");
    printf("Posicion|Dato\n");
    imprimirC(&Cadenas);
}




%}

salto_linea [\r\n]

op_arit     [+\-/*%]
op_logic    (&&)|(\|\|)|(!)
op_rel      ==|!=|>|<|>=|<=
const_ent   (\([-+][0-9]+\)|[0-9]+)
pal_res     assinado|caso|enquanto|fazer|flutuador|inteiro|para|quebrar|retorno|se|trocar
identif     _[a-zA-Z]+([a-zA-Z]|[0-9]|_)*
simb_esp    [(){};,:#\[|\]]
op_asig     "="|"+="|"-="|"*="|"-="|"*="|"/="|"%="
cadena      \"[^\"]*\"
op_cade     &|like

espacio    [" "]


%%

{espacio}
{op_arit} {printf("%s es un operador aritmetico (0,%s)", yytext,yytext);
           fprintf(archSal,"%s es un operador aritmetico (0,%s)\n", yytext,yytext);
           fprintf(tokens,"(6,%s)\n",yytext);}

{op_logic} {printf("%s es un operador logico", yytext);
            fprintf(archSal,"%s es un operador logico (1,%d)\n", yytext, opLogicos(yytext));
            fprintf(tokens,"(1,%d)\n",opLogicos(yytext));}

{op_rel} {printf("%s es un operador relacional", yytext);
          fprintf(archSal,"%s es un operador relacional (2,%d)\n", yytext, opRelacionales(yytext));
          fprintf(tokens,"(2,%d)\n",opRelacionales(yytext));}

{const_ent} {printf("%s es una constante numerica entera", yytext);
             fprintf(archSal,"%s es una constante numerica entera (3,%s)\n", yytext, cteNumerica(yytext));
             fprintf(tokens,"(3,%s)\n",cteNumerica(yytext));
             }

{pal_res} {printf("%s es una palabra reservada", yytext);
           fprintf(archSal,"%s es una palabra reservada (4,%d)\n", yytext, palReservada(yytext));
           fprintf(tokens,"(4,%d)\n",palReservada(yytext));}

{identif} {printf("%s es un identificador", yytext);
           fprintf(archSal,"%s es un identificador (5,%d)\n", yytext,TablaSimbolos(yytext));
           fprintf(tokens,"(5,%d)\n",TablaSimbolos(yytext));}


{simb_esp} {printf("%s es un simbolo especial (6,%s)", yytext, yytext);
            fprintf(archSal,"%s es un simbolo especial (6,%s)\n", yytext,yytext);
            fprintf(tokens,"(6,%s)\n",yytext);}

{op_asig} {printf("%s es un op_asig", yytext);
           fprintf(archSal,"%s es un operador de asignacion (7,%d)\n", yytext, opAsignacion(yytext));
           fprintf(tokens,"(7,%d)\n",opAsignacion(yytext));}


{cadena} {printf("%s es una cadena", yytext);
          fprintf(archSal,"%s es una cadena (8,%d)\n",yytext,n++);
          fprintf(tokens, "(8, %d)\n",constantescadena(yytext));}

{op_cade} {printf("%s es un operador sobre cadena", yytext);
           fprintf(archSal,"%s es un operador sobre cadena (9,%d)\n", yytext, opCadena(yytext));
           fprintf(tokens,"(9,%d)\n",opCadena(yytext));}

.         {printf("Error lexico: %s", yytext);
           fprintf(archSal,"Error lexico: %s\n",yytext);}



%%
//Funcion principal:
void main(int argn, char *argv[]){
    yyin = fopen(argv[1],"r");                       //Lee archivo .txt de entrada (en modo lectura)
    archSal = fopen("salida.txt","w");               //Archivo de salida que almacenara cadenas del archivo de entrada, clase y token
                                                     //Tambien los errores lexicos encontrados
    tokens = fopen("tokens.txt", "w");               //Archivo de salida que almacena solo los tokens generados del archivo de entrada
    fprintf(tokens, "Tokens generados: \n");         //Imprime un texto en el archivo tokens.txt
    
    /*
    Generacion de listas ligadas para los catalogos de palabras reservadas, op. relacional, op. logico, op. sobre cadenas
    y op. asignacion
    */

    Lista *tablaPalRes = crearLista();
    Lista *tablaOpRel = crearLista();
    Lista *tablaOpLog = crearLista();
    Lista *tablaOpCadenas = crearLista();
    Lista *tablaOpAsig = crearLista();

    //Tabla palabras reservadas
    insertar(tablaPalRes,crearNodo(0,"assinado"));
    insertar(tablaPalRes,crearNodo(1,"caso"));
    insertar(tablaPalRes,crearNodo(2,"enquanto"));
    insertar(tablaPalRes,crearNodo(3,"fazer"));
    insertar(tablaPalRes,crearNodo(4,"flutuador"));
    insertar(tablaPalRes,crearNodo(5,"inteiro"));
    insertar(tablaPalRes,crearNodo(6,"para"));
    insertar(tablaPalRes,crearNodo(7,"quebrar"));
    insertar(tablaPalRes,crearNodo(8,"retorno"));
    insertar(tablaPalRes,crearNodo(9,"se"));
    insertar(tablaPalRes,crearNodo(10,"trocar"));

    //Tabla palabras operadores relacionales
    insertar(tablaOpRel,crearNodo(0,"=="));
    insertar(tablaOpRel,crearNodo(1,"!="));
    insertar(tablaOpRel,crearNodo(2,">"));
    insertar(tablaOpRel,crearNodo(3,"<"));
    insertar(tablaOpRel,crearNodo(4,">="));
    insertar(tablaOpRel,crearNodo(5,"<="));

    //Tabla palabras operadores logicos
    insertar(tablaOpLog,crearNodo(0,"&&"));
    insertar(tablaOpLog,crearNodo(1,"||"));
    insertar(tablaOpLog,crearNodo(2,"!"));

    //Tabla palabras operadores sobre cadenas
    insertar(tablaOpCadenas,crearNodo(0,"&"));
    insertar(tablaOpCadenas,crearNodo(1,"like"));

    //Tabla palabras operadores de asignacion
    insertar(tablaOpAsig,crearNodo(0,"="));
    insertar(tablaOpAsig,crearNodo(1,"+="));
    insertar(tablaOpAsig,crearNodo(2,"-="));
    insertar(tablaOpAsig,crearNodo(3,"*="));
    insertar(tablaOpAsig,crearNodo(4,"/="));
    insertar(tablaOpAsig,crearNodo(5,"%="));

    printf("Catalogo de palabras reservadas: \n");
    printLista(tablaPalRes);

    printf("\nCatalogo de operadores relacionales: \n");
    printLista(tablaOpRel);

    printf("\nCatalogo de operadores logicos: \n");
    printLista(tablaOpLog);
    
    printf("\nCatalogo de operadores sobre cadenas: \n");
    printLista(tablaOpCadenas);

    printf("\nCatalogo de operadores de asignacion: \n");
    printLista(tablaOpAsig);


    yylex();

    printf("------------------------------------------\n");
    printf("------------------Tablas------------------\n");
    printf("------------------------------------------\n");
    mostrarTablas();
    printf("\nLos tokens muestran en el archivo tokens.txt\n");

    fclose(yyin);
    fclose(archSal);
    fclose(tokens);


}