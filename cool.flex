%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
int int_const_idx = 0;
int str_const_idx = 0;
int id_idx = 0;

void push_char(char c) {
  if (string_buf_ptr - string_buf < MAX_STR_CONST) {
    *string_buf_ptr++ = c;
  }
}

%}

/*
 * Define names for regular expressions here.
 */
CHAR            [\;\:\,\{\}\+\-\*\/\~\<\=\(\)\@\.]
CLASS           (?i:class)
ELSE            (?i:else)
FI              (?i:fi)
IN              (?i:in)
INHERITS        (?i:inherits)
LET             (?i:let)
LOOP            (?i:loop)
POOL            (?i:pool)
THEN            (?i:then)
WHILE           (?i:while)
CASE            (?i:case)
ESAC            (?i:esac)
OF              (?i:of)
DARROW          =>
NEW            (?i:new)
ISVOID         (?i:isvoid)
ASSIGN          <-
NOT            (?i:not)
LE             <=

INT            [0-9]+

TRUE           t(?i:rue)
FALSE          f(?i:alse)

TYPEID         [A-Z][A-Za-z0-9_]*
OBJECTID       [a-z][A-Za-z0-9_]*

%x STR
%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
\n         curr_lineno++;
{DARROW}   return (DARROW);
{ASSIGN}   return (ASSIGN);
{LE}       return (LE);

{CHAR}     return yytext[0];

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}     return (CLASS);
{ELSE}      return (ELSE);
{FI}        return (FI);
{IN}        return (IN);
{INHERITS}  return (INHERITS);
{LET}       return (LET);
{LOOP}      return (LOOP);
{POOL}      return (POOL);
{THEN}      return (THEN);
{WHILE}     return (WHILE);
{CASE}      return (CASE);
{ESAC}      return (ESAC);
{OF}        return (OF);
{NEW}       return (NEW);
{ISVOID}    return (ISVOID);
{NOT}       return (NOT);

{TRUE}     cool_yylval.boolean = true; return (BOOL_CONST);
{FALSE}    cool_yylval.boolean = false; return (BOOL_CONST);

{INT} {
  cool_yylval.symbol = new IntEntry(yytext, strlen(yytext), int_const_idx++);
  return (INT_CONST);
}

{TYPEID}  { cool_yylval.symbol = new IdEntry(yytext, strlen(yytext), id_idx++);
            return (TYPEID);
          }

{OBJECTID}  { cool_yylval.symbol = new IdEntry(yytext, strlen(yytext), id_idx++);
            return (OBJECTID);
          }
 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\" { string_buf_ptr = string_buf; BEGIN(STR); }

<STR>\"  {
  BEGIN(INITIAL);
  if (string_buf_ptr - string_buf < MAX_STR_CONST) {
    *string_buf_ptr = '\0';
    printf("%d", strlen(string_buf));
    cool_yylval.symbol = new StringEntry(string_buf, strlen(string_buf), str_const_idx++);
    return (STR_CONST);
  } else {
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
}

<STR>\\t  push_char('\t');
<STR>\\b  push_char('\b');
<STR>\\n  push_char('\n');
<STR>\\f  push_char('\f');
<STR>\\.  push_char(yytext[1]);

<STR>[^\\\n\"\0]+  {
  char *yptr = yytext;
  while (*yptr) {
    push_char(*yptr++);
  }          
}

<STR>\\?\n  {
  BEGIN(INITIAL);
  unput('\n');
  cool_yylval.error_msg = "Unterminated string constant";
  return (ERROR);
}

<STR>\0  {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "String contains null character";
  return (ERROR);
}

<STR><<EOF>> {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "EOF in string constant";
  return (ERROR);
}

%%
