%{
/* 
Programa 3 (Analizador Semantico)

Objetivo:
Construir en un mismo programa, los analizadores Léxico, Sintáctico, Semántico que
revisen programas fuente escritos con el lenguaje elaborado en clase.


Elaborador por:
- Garcia Lopez Erik
- Serapio Hernandez Alexis Arturo

Fecha de elaboracion: 30/11/2023

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

FILE *cadenaAtomos;  //Archivo para la cadena de atomos
FILE *archSal;  //Archivo para la salida
FILE *tokens;   //Archivo para los tokens
FILE *erroresSint; //Archivo para los errores sintacticos

int im = 0;   //Bandera auxiliar en la tabla de simbolos
int im1 = 0;  //Bandera auxiliar en la tabla de literales para cadenas
int im2 = 0; 

int n = 0;

//Variables para analizador sintactico
char atomos[2048];    //Aqui se almacenaran los atomos que se vayan generando
int erroresLex = 0;   //Cuanta el numero de errores lexicos
int erroresSin = 0;   //Cuenta el numero de errores sintacticos

//Variables para el analizador semantico
char c;               //Almacenara el dato actual de la cadena de atomos
int arrayValores[2048];

int tipo;             //Almacena el tipo de dato
int posicion = 0;     //Sirve para ubicarnos en la cadena de atomos

int posicionAT=0;


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
//Regresa 02 si no se encuentra en la tabla
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
        else{ //Si no es la primera vez lo busca en la TS. Regresa -2 si no se encuentra en la tabla, se crea un nuevo identificador y se agrega a la tabla
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

//-------------------------------------------------------------------------------------//
//------------------------Funciones para crear cadena de atomos------------------------//
//-------------------------------------------------------------------------------------//

void opArtimeticosCA(char *or1){
    if (!strcmp(or1,"+")){
        fprintf(cadenaAtomos,"+");
    } else if (!strcmp(or1,"-")){
        fprintf(cadenaAtomos,"-");
    } else if (!strcmp(or1,"/")){
        fprintf(cadenaAtomos,"/");
    } else if (!strcmp(or1,"*")){
        fprintf(cadenaAtomos,"*");
    } else if (!strcmp(or1,"%")){
        fprintf(cadenaAtomos,"%s","%");
    }
}

int opLogicosCA(char *or1){
    if (!strcmp(or1,"&&")){
        fprintf(cadenaAtomos,"h");
        return 0;
    } else if (!strcmp(or1,"||")){
        fprintf(cadenaAtomos,"j");
        return 1;
    } else if (!strcmp(or1,"!")){
        fprintf(cadenaAtomos,"!");
        return 2;
    } else {
        return -1;
    }
}

int opRelacionalesCA(char *or1){
    if (!strcmp(or1,"==")){
        fprintf(cadenaAtomos,"e");
        return 0;
    } else if (!strcmp(or1,"!=")){
        fprintf(cadenaAtomos,"d");
        return 1;
    } else if (!strcmp(or1,">")){
        fprintf(cadenaAtomos,">");
        return 2;
    } else if (!strcmp(or1,"<")){
        fprintf(cadenaAtomos,"<");
        return 3;
    } else if (!strcmp(or1,">=")){
        fprintf(cadenaAtomos,"m");
        return 4;
    } else if (!strcmp(or1,"<=")){
        fprintf(cadenaAtomos,"w");
        return 5;
    } else {
        return -1;
    }
}

int palResCA(char *pr){
    if (!strcmp(pr,"assinado")){
        fprintf(cadenaAtomos,"g");
        return 0;
    } else if (!strcmp(pr,"caso")){
        fprintf(cadenaAtomos,"c");
        return 1;
    } else if (!strcmp(pr,"enquanto")){
        fprintf(cadenaAtomos,"q");
        return 2;
    } else if (!strcmp(pr,"fazer")){
        fprintf(cadenaAtomos,"z");
        return 3;
    } else if (!strcmp(pr,"flutuador")){
        fprintf(cadenaAtomos,"f");
        return 4;
    } else if (!strcmp(pr,"inteiro")){
        fprintf(cadenaAtomos,"i");
        return 5;
    } else if (!strcmp(pr,"para")){
        fprintf(cadenaAtomos,"p");
        return 6;
    } else if (!strcmp(pr,"quebrar")){
        fprintf(cadenaAtomos,"u");
        return 7;
    } else if (!strcmp(pr,"retorno")){
        fprintf(cadenaAtomos,"t");
        return 8;
    } else if (!strcmp(pr,"se")){
        fprintf(cadenaAtomos,"s");
        return 9;
    } else if (!strcmp(pr,"trocar")){
        fprintf(cadenaAtomos,"b");
        return 10;
    } else {
        return -1;
    }
}

void simbEspCA(char *or1){
    if (!strcmp(or1,"(")){
        fprintf(cadenaAtomos,"(");
    } else if (!strcmp(or1,")")){
        fprintf(cadenaAtomos,")");
    } else if (!strcmp(or1,"{")){
        fprintf(cadenaAtomos,"{");
    } else if (!strcmp(or1,"}")){
        fprintf(cadenaAtomos,"}");
    } else if (!strcmp(or1,";")){
        fprintf(cadenaAtomos,";");
    } else if (!strcmp(or1,",")){
        fprintf(cadenaAtomos,",");
    } else if (!strcmp(or1,"[")){
        fprintf(cadenaAtomos,"[");
    } else if (!strcmp(or1,"]")){
        fprintf(cadenaAtomos,"]");
    } else if (!strcmp(or1,":")){
        fprintf(cadenaAtomos,":");
    } else if (!strcmp(or1,"#")){
        fprintf(cadenaAtomos,"#");
    }
}

int opAsignacionCA(char *or1){
    if (!strcmp(or1,"=")){
        fprintf(cadenaAtomos,"=");
        return 0;
    } else if (!strcmp(or1,"+=")){
        fprintf(cadenaAtomos,"x");
        return 1;
    } else if (!strcmp(or1,"-=")){
        fprintf(cadenaAtomos,"y");
        return 2;
    } else if (!strcmp(or1,"*=")){
        fprintf(cadenaAtomos,"k");
        return 3;
    } else if (!strcmp(or1,"/=")){
        fprintf(cadenaAtomos,"r");
        return 4;
    } else if (!strcmp(or1,"%=")){
        fprintf(cadenaAtomos,"o");
        return 5;
    } else {
        return -1;
    }
}

int opCadenaCA(char *or1){
    if (!strcmp(or1,"&")){
        fprintf(cadenaAtomos,"&");
        return 0;
    } else if (!strcmp(or1,"like")){
        fprintf(cadenaAtomos,"l");
        return 1;
    } else {
        return -1;
    }
}

void rechaza(char* esperado){
    printf("Error sintactico\n");
    printf("Caracter: %c   Posicion: %d   Esperado: %s\n\n", c, posicion, esperado);
    posicion++;
    c = atomos[posicion];
    erroresSin++;
}

//------------------Prototipos para las funciones recursivas del Analizador Sintactico Descendente------------------//
void Program();
void otraFunc();
void Func();
int TipoF();              //Aqui se obtiene el tipo de dato
void listArg();
void otroArg();
void Cuerpo();
void listDecl();
void Decl();
int Tipo();               //Aqui se obtiene el tipo de dato
void valorIni();
void listaVar();
void tipoVal();
void Asig();
void opArit();
void E();
void EP();
void T();
void TP();
void F();
void R();
void opRel();
void Sent();
void listaS();
void expLogica();
void expLog();
void expRel();
void opLog();
void Enq();
void Se();
void Q();
void Faz();
void Ret();
void valRet();
void expCad();
void opCad();
void Para();
void Trocar();
void casos();
void Llama();
void listP();
void Param();

//-----Funciones para el semantico-----//

// Obtener el tipo a partir de la posición en la lista de símbolos
int obtenerTipoActual(int posicion) {
    struct Iden *a = Simbolos.raiz;
    while (a != NULL) {
        if (a->posicion == posicion) {
            return a->tipo;
        }
        a = a->next;
    }
    return -1; // Devuelve -1 si no se encuentra la posición en la tabla de símbolos
}

int banderita = 0;

// Función que consulta la tabla de símbolos y actualiza el tipo
// Si ya se ha declarado la variable, muestra una advertencia
void asignaTipo(int tipo, int posicion) {
    struct Iden *actual = Simbolos.raiz;

    while (actual != NULL) {
        if (actual->posicion == posicion) {
            actual->tipo = tipo;
            return;
        }
        actual = actual->next;
    }
    // En este punto, la posición no se encontró en la tabla de símbolos.
    //printf("ERROR: No se encontró la posición %d en la tabla de símbolos\n", posicion);
    banderita++;

}


int VAT(int tipo, int posicion){
    int actual = obtenerTipoActual(posicion);

    if (actual == -1){
        asignaTipo(tipo, posicion);
        return 0;
    } else {
        printf("La variable ya fue declarada anteriormenteeeeee");
        //printf("ADVERTENCIA: Variable '%s' ya declarada anteriormente\n", obtenerTipoActual(posicion));
        return -1;
    }
}

/*
struct Iden *primerRegistro = NULL;

// Función que consulta la tabla de símbolos y actualiza el tipo
// Si ya se ha declarado la variable, muestra una advertencia
void asignaTipo(int tipo, int posicion) {
    struct Iden *actual = primerRegistro;

    while (actual != NULL) {

      if(actual->){

      }
    }
}
*/











%}

salto_linea [\r\n]

op_arit     [+\-/*%]
op_logic    (&&)|(\|\|)|(!)
op_rel      ==|!=|>|<|>=|<=
const_ent   (\([\-+][0-9]+\)|[0-9]+)
pal_res     assinado|caso|enquanto|fazer|flutuador|inteiro|para|quebrar|retorno|se|trocar
identif     _[a-zA-Z]+([a-zA-Z]|[0-9]|_)*
simb_esp    [(){};,:#\[|\]]
op_asig     "="|"+="|"-="|"*="|"-="|"*="|"/="|"%="
cadena      \"[^\"]*\"
op_cade     &|like

espacio    [" "]


%%

{espacio}
{op_arit} {//printf("%s es un operador aritmetico (0,%s)", yytext,yytext);
           fprintf(archSal,"%s es un operador aritmetico (0,%s)\n", yytext,yytext);
           fprintf(tokens,"(6,%s)\n",yytext);
           opArtimeticosCA(yytext);}

{op_logic} {//printf("%s es un operador logico", yytext);
            fprintf(archSal,"%s es un operador logico (1,%d)\n", yytext, opLogicos(yytext));
            fprintf(tokens,"(1,%d)\n",opLogicosCA(yytext));}

{op_rel} {//printf("%s es un operador relacional", yytext);
          fprintf(archSal,"%s es un operador relacional (2,%d)\n", yytext, opRelacionales(yytext));
          fprintf(tokens,"(2,%d)\n",opRelacionalesCA(yytext));}

{const_ent} {//printf("%s es una constante numerica entera", yytext);
             fprintf(archSal,"%s es una constante numerica entera (3,%s)\n", yytext, cteNumerica(yytext));
             fprintf(tokens,"(3,%s)\n",cteNumerica(yytext));
             fprintf(cadenaAtomos,"n");}

{pal_res} {//printf("%s es una palabra reservada", yytext);
           fprintf(archSal,"%s es una palabra reservada (4,%d)\n", yytext, palReservada(yytext));
           fprintf(tokens,"(4,%d)\n",palResCA(yytext));}

{identif} {//printf("%s es un identificador", yytext);
           fprintf(archSal,"%s es un identificador (5,%d)\n", yytext,TablaSimbolos(yytext));
           fprintf(tokens,"(5,%d)\n",TablaSimbolos(yytext));
           fprintf(cadenaAtomos,"a");}


{simb_esp} {//printf("%s es un simbolo especial (6,%s)", yytext, yytext);
            fprintf(archSal,"%s es un simbolo especial (6,%s)\n", yytext,yytext);
            fprintf(tokens,"(6,%s)\n",yytext);
            simbEspCA(yytext);}

{op_asig} {//printf("%s es un op_asig", yytext);
           fprintf(archSal,"%s es un operador de asignacion (7,%d)\n", yytext, opAsignacion(yytext));
           fprintf(tokens,"(7,%d)\n",opAsignacionCA(yytext));}


{cadena} {//printf("%s es una cadena", yytext);
          fprintf(archSal,"%s es una cadena (8,%d)\n",yytext,n++);
          fprintf(tokens, "(8, %d)\n",constantescadena(yytext));
          fprintf(cadenaAtomos,"v");}

{op_cade} {//printf("%s es un operador sobre cadena", yytext);
           fprintf(archSal,"%s es un operador sobre cadena (9,%d)\n", yytext, opCadena(yytext));
           fprintf(tokens,"(9,%d)\n",opCadenaCA(yytext));}

.         {printf("Error lexico: %s", yytext);
           fprintf(archSal,"Error lexico: %s\n",yytext);
           erroresLex++;}



%%
//Funcion principal:
void main(int argn, char *argv[]){
    yyin = fopen(argv[1],"r");                       //Lee archivo .txt de entrada (en modo lectura)
    archSal = fopen("salida.txt","w");               //Archivo de salida que almacenara cadenas del archivo de entrada, clase y token, tambien los errores lexicos encontrados
    tokens = fopen("tokens.txt", "w");               //Archivo de salida que almacena solo los tokens generados del archivo de entrada
    cadenaAtomos = fopen("cadena.txt", "w+");        //Archivo para la cadena de atomos
    erroresSint = fopen("erroresS.txt", "w+");       //Archivo para los errores sintacticos
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

    printf("-------------------------Analizador sintactico-------------------------\n\n");
    printf("Se genero la cadena de atomos en el archivo cadena.txt\n");
    fprintf(cadenaAtomos,"$\n");
    rewind(cadenaAtomos);
    fscanf(cadenaAtomos, "%s", atomos);
    printf("La cadena de atomos es: %s\n\n", atomos);
    c = atomos[0];
    Program(); //Aqui se manda a llamar a las funciones del ASD

    //Muestra si encontro errores lexicos y/o semanticos
    if(erroresLex == 0) {
            if(erroresSin== 0){
            printf("La cadena es aceptada (esta bien lexicamente y sintacticamente)");
            }
        }
        if(erroresLex > 0){
            printf("Cadena rechazada. Se encontraron errores Léxicos!  ");
            printf("Errores Léxicos = %i \n", erroresLex);
        }
        if(erroresSin >0){
            printf("Cadena rechazada. Se encontraron errores Sintácticos!");
            printf("Errores Sintácticos = %i \n", erroresSin);
        }else{
        printf("\nEs sintácticamente correcto\n");
        }

    printf("-------------------------Analizador Semantico-------------------------\n\n");

    printf("Tabla de simbolos: \n");
    printf("Posicion|Nombre|Tipo\n");
    imprimirS(&Simbolos);    

    if (banderita >= 1){
      printf("\nERROR: Hay %d identificador(es) repetido(s)\n", banderita);
      printf("Revisar declaraciones de variables\n");
    } else{
      printf("\nPrograma correcto semanticamente, se han asignado los tipos de dato.\n");
    }

    fclose(yyin);
    fclose(archSal);
    fclose(tokens);
    fclose(cadenaAtomos);
    fclose(erroresSint);


}


//-----------------------------Seccion de funciones del analizador sintactico-----------------------------//

/*
Cada función representa un no terminal dentro de la gramática que define
la sintáxis de nuestro lenguaje, los "ifs" preguntan si el átomo ingresado 
a la función es igual a alguno de los conjuntos de selección de sus producciones
en caso de que si, sigue el proceso, en caso contrario, entra a la función rechaza
donde muestra el error sintáctico presentado, es decir, el átomo, la posición 
dentro de la cadena y el o los átomos que esperaba el analizador sintáctico. 

Es importante destacar que las funciones son recursivas y por consiguiente todas
las funciones estan conectadas de alguna forma para el análisis sintáctico.
*/


void Program() {
  if (c == 'f' || c == 'i' || c == 'g') {
    Func();
    otraFunc();
    return;
  } else {
    rechaza("f | i | g");
    return;
  }
}

void otraFunc() {
  if (c == 'f' || c == 'i' || c == 'g') {
    Func();
    otraFunc();
    return;
  } else if (c == '$') {
    return;
  } else {
    rechaza("f | i | g | $");
    return;
  }
}

void Func() {
  if (c == 'f' || c == 'i' || c == 'g') {
    tipo = TipoF();
    if (c == 'a') {
      VAT(tipo, posicionAT);
      posicionAT++;
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("a");
    }
    if (c == '(') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("(");
    }
    listArg();
    if (c == ')') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza(")");
    }
    if (c == '{') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("{");
    }
    Cuerpo();
    if (c == '}') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("}");
    }
    return;
  } else {
    rechaza("f | i | g");
    return;
  }
}

int TipoF() {
  if (c == 'f' || c == 'i') {
    tipo = Tipo();
    return tipo;
  } else if (c == 'g') {
    posicion++;
    c = atomos[posicion];
    return 0;
  } else {
    rechaza("f | i | g");
    return -1;
  }
}

void listArg() {
  if (c == 'f' || c == 'i') {
    tipo = Tipo();
    if (c == 'a') {
      VAT(tipo, posicionAT);
      posicionAT++;
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("a");
      return;
    }
    otroArg();
    return;
  } else if (c == ')') {
    return;
  } else {
    rechaza("f | i | )");
    return;
  }
}

void otroArg() {
  if (c == ',') {
    posicion++;
    c = atomos[posicion];
    tipo = Tipo();
    if (c == 'a') {
      VAT(tipo, posicionAT);
      posicionAT++;
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("a");
      return;
    }
    otroArg();
    return;
  } else if (c == ')') {
    return;
  } else {
    rechaza(", | )");
  }
}

void Cuerpo() {
  if (c == 'f' || c == 'i' || c == 'a' || c == 'u' || c == 't' || c == 'b' || c == 'q' || c == 'z' || c == 's' || c == 'p' || c == '[') {
    listDecl();
    listaS();
    return;
  } else {
    rechaza("f | i | a | u | t | b | q | z | s | p | [ | f | i");
    return;
  }
}

void listDecl() {
  if (c == 'a' || c == 'u' || c == 't' || c == 'b' || c == 'q' || c == 'z' || c == 's' || c == 'p' || c == '[' || c == '}') {
    return;
  } else if (c == 'f' || c == 'i') {
    Decl();
    listDecl();
    return;
  } else {
    rechaza("a | u | t | b | q | z | s | p | [ | f | i");
    return;
  }
}

void Decl() {
  if (c == 'f' || c == 'i') {
    tipo = Tipo();
    if (c == 'a') {
      VAT(tipo, posicionAT);
      posicionAT++;
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("a");
    }
    valorIni();
    listaVar();
    if (c == ';') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza(";");
    }
    return;
  } else {
    rechaza("f | i");
  }
}

int Tipo() {
  if (c == 'f') {
    posicion++;
    c = atomos[posicion];
    return 4;
  } else if (c == 'i') {
    posicion++;
    c = atomos[posicion];
    return 5;
  } else {
    rechaza("f | i");
    return -1;
  }
}

void valorIni() {
  if (c == '=') {
    posicion++;
    c = atomos[posicion];
    tipoVal();
    return;
  } else if (c == ',' || c == ';') {
    return;
  } else {
    rechaza("= | , | ;");
    return;
  }
}

void listaVar() {
  if (c == ',') {
    posicion++;
    c = atomos[posicion];
    if (c == 'a') {
      VAT(tipo, posicionAT);
      posicionAT++;
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("a");
    }
    valorIni();
    listaVar();
    return;
  } else if (c == ';') {
    return;
  } else {
    rechaza(", | ;");
    return;
  }
}

void tipoVal() {
  if (c == 'n') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'v') {
    posicion++;
    c = atomos[posicion];
    return;
  } else {
    rechaza("n | v");
    return;
  }
}
void Asig() {
  if (c == 'a') {
    VAT(tipo, posicionAT);
    posicionAT++;
    posicion++;
    c = atomos[posicion];
    opArit();
    E();
    if (c == ';') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza(";");
    }
    return;
  } else {
    rechaza("a");
    return;
  }
}

void opArit() {
  if (c == '=') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'x') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'y') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'k') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'r') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'o') {
    posicion++;
    c = atomos[posicion];
    return;
  } else {
    rechaza("= | x | y | k | r | o");
    return;
  }
}

void E() {
  if (c == '(' || c == 'a' || c == 'n' || c == '[') {
    T();
    EP();
    return;
  } else {
    rechaza("( | a | n | [");
    return;
  }
}

void EP() {
  if (c == '+') {
    posicion++;
    c = atomos[posicion];
    T();
    EP();
    return;
  } else if (c == '-') {
    posicion++;
    c = atomos[posicion];
    T();
    EP();
    return;
  } else if (c == ';' || c == ')' || c == '>' || c == '<' || c == 'e' || c == 'd' || c == 'm' || c == 'w' || c == 'h' || c == 'j' || c == ',') {
    return;
  } else {
    rechaza("+ | - | ; | ) | > | < | e | d | m | w | h | j | ,");
    return;
  }
}

void T() {
  if (c == '(' || c == 'a' || c == 'n' || c == '[') {
    F();
    TP();
    return;
  } else {
    rechaza("( | a | n | [");
    return;
  }
}

void TP() {
  if (c == '*') {
    posicion++;
    c = atomos[posicion];
    F();
    TP();
    return;
  } else if (c == '/') {
    posicion++;
    c = atomos[posicion];
    F();
    TP();
    return;
  } else if (c == '%') {
    posicion++;
    c = atomos[posicion];
    F();
    TP();
    return;
  } else if (c == '+' || c == '-' || c == ';' || c == ')' || c == '>' || c == '<' || c == 'e' || c == 'd' || c == 'm' || c == 'w' || c == 'h' || c == 'j' || c == ',') {
    return;
  } else {
    rechaza("* | / | % | + | - | ; | ) | > | < | e | d | m | w | h | j | ,");
    return;
  }
}

void F() {
  if (c == '(') {
    posicion++;
    c = atomos[posicion];
    E();
    if (c == ')') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza(")");
    }
    return;
  } else if (c == 'a') {
    VAT(tipo, posicionAT);
    posicionAT++;
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'n') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == '[') {
    Llama();
    return;
  } else {
    rechaza("( | a | n | [");
    return;
  }
}

void R() {
  if (c == '(' || c == 'a' || c == 'n' || c == '[') {
    E();
    opRel();
    E();
    return;
  } else {
    rechaza("( | a | n | [");
    return;
  }
}

void opRel() {
  if (c == '>') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == '<') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'e') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'd') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'm') {
    posicion++;
    c = atomos[posicion];
    return;
  } else if (c == 'w') {
    posicion++;
    c = atomos[posicion];
    return;
  } else {
    rechaza("> | < | e | d | m | w");
    return;
  }
}

void Sent() {
  if (c == 'a') {
    Asig();
    return;
  } else if (c == 'u') {
    Q();
    return;
  } else if (c == 't') {
    Ret();
    return;
  } else if (c == 'b') {
    Trocar();
    return;
  } else if (c == 'q') {
    Enq();
    return;
  } else if (c == 'z') {
    Faz();
    return;
  } else if (c == 's') {
    Se();
    return;
  } else if (c == 'p') {
    Para();
    return;
  } else if (c == '[') {
    Llama();
    return;
  } else {
    rechaza("a | u | t | b | q | z | s | p | [ ");
    return;
  }
}

void listaS() {
  if (c == 'a' || c == 'u' || c == 't' || c == 'b' || c == 'q' || c == 'z' || c == 's' || c == 'p' || c == '[') {
    Sent();
    listaS();
    return;
  } else if (c == '}' || c == '#') {
    return;
  } else {
    rechaza("a | u | t | b | q | z | s | p | [ ");
    return;
  }
}

void expLogica() {
  if (c == '!') {
    posicion++;
    c = atomos[posicion];
    expRel();
    return;
  } else if (c == '(' || c == 'a' || c == 'n' || c == '[') {
    R();
    expLog();
    return;
  } else {
    rechaza("! | ( | a | n | [ ");
    return;
  }
}

void expLog() {
  if (c == 'h' || c == 'j') {
    opLog();
    R();
    return;
  } else if (c == ')') {
    return;
  } else {
    rechaza("h | j | )");
    return;
  }
}

void expRel() {
  if (c == '{') {
    posicion++;
    c = atomos[posicion];
    R();
    if (c == '}') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("} ");
      return;
    }
    return;
  } else if (c == '(' || c == 'a' || c == 'n' || c == '[') {
    E();
    return;
  } else {
    rechaza("{ | ( | a | n | [");
    return;
  }
}

void opLog() {
  if (c == 'h' || c == 'j') {
    posicion++;
    c = atomos[posicion];
    return;
  } else {
    rechaza("h | j ");
    return;
  }
}

void Enq() {
  if (c == 'q') {
    posicion++;
    c = atomos[posicion];
    if (c == '(') {
      posicion++;
      c = atomos[posicion];
      expLogica();
      if (c == ')') {
        posicion++;
        c = atomos[posicion];
        if (c == '#') {
          posicion++;
          c = atomos[posicion];
          listaS();
          if (c == '#') {
            posicion++;
            c = atomos[posicion];
          } else {
            rechaza("# ");
            return;
          }
        } else {
          rechaza("# ");
          return;
        }
      } else {
        rechaza(") ");
        return;
      }
    } else {
      rechaza("( ");
      return;
    }
    return;
  } else {
    rechaza("q ");
    return;
  }
}

void Se() {
  if (c == 's') {
    posicion++;
    c = atomos[posicion];
    if (c == '(') {
      posicion++;
      c = atomos[posicion];
      expLogica();
      if (c == ')') {
        posicion++;
        c = atomos[posicion];
        if (c == '#') {
          posicion++;
          c = atomos[posicion];
          listaS();
          if (c == '#') {
            posicion++;
            c = atomos[posicion];
          } else {
            rechaza("# ");
            return;
          }
        } else {
          rechaza("# ");
          return;
        }
      } else {
        rechaza(") ");
        return;
      }
    } else {
      rechaza("( ");
      return;
    }
    return;
  } else {
    rechaza("q ");
    return;
  }
}

void Q() {
  if (c == 'u') {
    posicion++;
    c = atomos[posicion];
    if (c == ';') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("; ");
      return;
    }
    return;
  } else {
    rechaza("u ");
    return;
  }
}

void Faz() {
  if (c == 'z') {
    posicion++;
    c = atomos[posicion];
    if (c == '#') {
      posicion++;
      c = atomos[posicion];
      listaS();
      if (c == '#') {
        posicion++;
        c = atomos[posicion];
        if (c == 'q') {
          posicion++;
          c = atomos[posicion];
          if (c == '(') {
            posicion++;
            c = atomos[posicion];
            expLogica();
            if (c == ')') {
              posicion++;
              c = atomos[posicion];
              if (c == ';') {
                posicion++;
                c = atomos[posicion];
              } else {
                rechaza("; ");
                return;
              }
            } else {
              rechaza(") ");
              return;
            }
          } else {
            rechaza("( ");
            return;
          }
        } else {
          rechaza("q ");
          return;
        }
      } else {
        rechaza("# ");
        return;
      }
    } else {
      rechaza("# ");
      return;
    }
    return;
  } else {
    rechaza("z ");
    return;
  }
}

void Ret() {
  if (c == 't') {
    posicion++;
    c = atomos[posicion];
    valRet();
    if (c == ';') {
      posicion++;
      c = atomos[posicion];
    } else {
      rechaza("; ");
      return;
    }
    return;
  } else {
    rechaza("t ");
    return;
  }
}

void valRet() {
  if (c == '(' || c == 'a' || c == 'n' || c == '[') {
    E();
    return;
  } else if (c == '{') {
    posicion++;
    c = atomos[posicion];
    expCad();
    if (c == '}') {
      posicion++;
      c = atomos[posicion];
      return;
    } else {
      rechaza("} ");
      return;
    }
  } else if (c == ';') {
    return;
  } else {
    rechaza("( | a | n | [ | { | ;");
    return;
  }
}

void expCad() {
  if (c == 'a') {
    VAT(tipo, posicionAT);
    posicionAT++;
    posicion++;
    c = atomos[posicion];
    opCad();
    return;
  } else if (c == 'v') {
    posicion++;
    c = atomos[posicion];
    opCad();
    return;
  } else {
    rechaza("a | v ");
    return;
  }
}

void opCad() {
  if (c == 'l') {
    posicion++;
    c = atomos[posicion];
    expCad();
    return;
  } else if (c == 'h') {
    posicion++;
    c = atomos[posicion];
    expCad();
    return;
  } else if (c == '}') {
    return;
  } else {
    rechaza("l | h | }");
    return;
  }
}

void Para() {
  if (c == 'p') {
    posicion++;
    c = atomos[posicion];
    if (c == 'a') {
      VAT(tipo, posicionAT);
      posicionAT++;
      posicion++;
      c = atomos[posicion];
      if (c == '[') {
        posicion++;
        c = atomos[posicion];
        if (c == 'n') {
          posicion++;
          c = atomos[posicion];
          if (c == ',') {
            posicion++;
            c = atomos[posicion];
            if (c == 'n') {
              posicion++;
              c = atomos[posicion];
              if (c == ']') {
                posicion++;
                c = atomos[posicion];
                if (c == '#') {
                  posicion++;
                  c = atomos[posicion];
                  listaS();
                  if (c == '#') {
                    posicion++;
                    c = atomos[posicion];
                  } else {
                    rechaza("# ");
                    return;
                  }
                } else {
                  rechaza("# ");
                  return;
                }
              } else {
                rechaza("] ");
                return;
              }
            } else {
              rechaza("n ");
              return;
            }
          } else {
            rechaza(", ");
            return;
          }
        } else {
          rechaza("n ");
          return;
        }
      } else {
        rechaza("[ ");
        return;
      }
    } else {
      rechaza("a ");
      return;
    }
    return;
  } else {
    rechaza("p ");
    return;
  }
}

void Trocar() {
  if (c == 'b') {
    posicion++;
    c = atomos[posicion];
    if (c == '(') {
      posicion++;
      c = atomos[posicion];
      if (c == 'a') {
        VAT(tipo, posicionAT);
        posicionAT++;
        posicion++;
        c = atomos[posicion];
        if (c == ')') {
          posicion++;
          c = atomos[posicion];
          if (c == ':') {
            posicion++;
            c = atomos[posicion];
            if (c == '#') {
              posicion++;
              c = atomos[posicion];
              if (c == 'c') {
                posicion++;
                c = atomos[posicion];
                if (c == '(') {
                  posicion++;
                  c = atomos[posicion];
                  if (c == 'n') {
                    posicion++;
                    c = atomos[posicion];
                    if (c == ')') {
                      posicion++;
                      c = atomos[posicion];
                      if (c == '{') {
                        posicion++;
                        c = atomos[posicion];
                        listaS();
                        if (c == '}') {
                          posicion++;
                          c = atomos[posicion];
                          casos();
                          if (c == '#') {
                            posicion++;
                            c = atomos[posicion];
                          } else {
                            rechaza("# ");
                            return;
                          }
                        } else {
                          rechaza("} ");
                          return;
                        }
                      } else {
                        rechaza("{ ");
                        return;
                      }
                    } else {
                      rechaza(") ");
                      return;
                    }
                  } else {
                    rechaza("n ");
                    return;
                  }
                } else {
                  rechaza("( ");
                  return;
                }
              } else {
                rechaza("c ");
                return;
              }
            } else {
              rechaza("# ");
              return;
            }
          } else {
            rechaza(": ");
            return;
          }
        } else {
          rechaza(") ");
          return;
        }
      } else {
        rechaza("a ");
        return;
      }
    } else {
      rechaza("( ");
      return;
    }
    return;
  } else {
    rechaza("b ");
    return;
  }
}

void casos() {
  if (c == '#') {
    return;
  } else if (c == 'c') {
    posicion++;
    c = atomos[posicion];
    if (c == '(') {
      posicion++;
      c = atomos[posicion];
      if (c == 'n') {
        posicion++;
        c = atomos[posicion];
        if (c == ')') {
          posicion++;
          c = atomos[posicion];
          if (c == '{') {
            posicion++;
            c = atomos[posicion];
            listaS();
            if (c == '}') {
              posicion++;
              c = atomos[posicion];
              casos();
            } else {
              rechaza("} ");
              return;
            }
          } else {
            rechaza("{ ");
            return;
          }
        } else {
          rechaza(") ");
          return;
        }
      } else {
        rechaza("n ");
        return;
      }
    } else {
      rechaza("( ");
      return;
    }
    return;
  } else if (c == '(') {
    posicion++;
    c = atomos[posicion];
    if (c == ')') {
      posicion++;
      c = atomos[posicion];
      if (c == '{') {
        posicion++;
        c = atomos[posicion];
        listaS();
        if (c == '}') {
          posicion++;
          c = atomos[posicion];
          casos();
        } else {
          rechaza("} ");
          return;
        }
      } else {
        rechaza("{ ");
        return;
      }
    } else {
      rechaza(") ");
      return;
    }
    return;
  } else {
    rechaza("# | c | (");
    return;
  }
}

void Llama() {
  if (c == '[') {
    posicion++;
    c = atomos[posicion];
    if (c == 'a') {
      posicion++;
      c = atomos[posicion];
      if (c == '(') {
        posicion++;
        c = atomos[posicion];
        listP();
        if (c == ')') {
          posicion++;
          c = atomos[posicion];
          if (c == ']') {
            posicion++;
            c = atomos[posicion];
          } else {
            rechaza("] ");
            return;
          }
        } else {
          rechaza(") ");
          return;
        }
      } else {
        rechaza("( ");
        return;
      }
    } else {
      rechaza("a ");
      return;
    }
    return;
  } else {
    rechaza("[ ");
    return;
  }
}

void listP() {
  if (c == ')') {
    return;
  } else if (c == '(' || c == 'a' || c == 'n' || c == '[') {
    E();
    Param();
    return;
  } else if (c == '{') {
    posicion++;
    c = atomos[posicion];
    expCad();
    if (c == '}') {
      posicion++;
      c = atomos[posicion];
      Param();
    } else {
      rechaza("} ");
      return;
    }
    return;
  } else {
    rechaza(") | ( | a | n | [ | {");
    return;
  }
}

void Param() {
  if (c == ',') {
    posicion++;
    c = atomos[posicion];
    listP();
    return;
  } else if (c == ')') {
    return;
  } else {
    rechaza(", | ) ");
    return;
  }
}