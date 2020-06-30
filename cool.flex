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
int comment_nest_lvl = 0;

void push_char(char c) {
  if (string_buf_ptr - string_buf < MAX_STR_CONST) {
    *string_buf_ptr++ = c;
  }
}

%}

 /* Define names for regular expressions here. */

SINGLE_CHAR    [;:,\{\}\+\-\*/~<=\(\)@\.]
DARROW         =>
ASSIGN         <-
LE             <=
INT            [0-9]+
TYPEID         [A-Z][A-Za-z0-9_]*
OBJECTID       [a-z][A-Za-z0-9_]*

/* conditions */

%x str
%x comment
%%

 /* Whitespace */

\n  curr_lineno++;

[ \b\t\r\f\v] /* eat whitespace */

 /* Comments */

--.* /* eat -- and everything after it to the end of the line/file */

"(*"  comment_nest_lvl++; BEGIN(comment);

"*)"  {
  cool_yylval.error_msg = "Unmatched *)";
  return (ERROR);
}

<comment>[^(*\n]*          /* eat anything that's not a '*' or '(' */
<comment>"*"+[^*)(\n]*  /* eat up '*'s not followed by ')'s */
<comment>"("+[^*(\n]*  /* eat up '('s not followed by '*'s */
<comment>\n               curr_lineno++;
<comment>"(*"           comment_nest_lvl++;

<comment>"*"+")"  {
  if (--comment_nest_lvl == 0) {
    BEGIN(INITIAL);
  }
}

<comment><<EOF>> {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "EOF in comment";
  return (ERROR);
}

 /* The multiple-character operators */

{DARROW}   return (DARROW);
{ASSIGN}   return (ASSIGN);
{LE}       return (LE);

 /* The single-character operators. */

{SINGLE_CHAR}     return yytext[0];

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

(?i:class)     return (CLASS);
(?i:else)      return (ELSE);
(?i:fi)        return (FI);
(?i:if)        return (IF);
(?i:in)        return (IN);
(?i:inherits)  return (INHERITS);
(?i:let)       return (LET);
(?i:loop)      return (LOOP);
(?i:pool)      return (POOL);
(?i:then)      return (THEN);
(?i:while)     return (WHILE);
(?i:case)      return (CASE);
(?i:esac)      return (ESAC);
(?i:of)        return (OF);
(?i:new)       return (NEW);
(?i:isvoid)    return (ISVOID);
(?i:not)       return (NOT);

t(?i:rue)     cool_yylval.boolean = true; return (BOOL_CONST);
f(?i:alse)    cool_yylval.boolean = false; return (BOOL_CONST);

 /* Symbols - int constants, type ids, object ids */

{INT} {
  cool_yylval.symbol = new IntEntry(yytext, strlen(yytext), int_const_idx++);
  return (INT_CONST);
}

{TYPEID}  {
  cool_yylval.symbol = new IdEntry(yytext, strlen(yytext), id_idx++);
  return (TYPEID);
}

{OBJECTID}  {
  cool_yylval.symbol = new IdEntry(yytext, strlen(yytext), id_idx++);
  return (OBJECTID);
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  */

\" { string_buf_ptr = string_buf; BEGIN(str); }

<str>\"  {
  BEGIN(INITIAL);
  int len = string_buf_ptr - string_buf;
  if (len < MAX_STR_CONST) {
    *string_buf_ptr = '\0';
    if (strlen(string_buf) != len) {
      cool_yylval.error_msg = "String contains null character";
      return (ERROR);
    }
    cool_yylval.symbol = new StringEntry(string_buf, strlen(string_buf), str_const_idx++);
    return (STR_CONST);
  } else {
    cool_yylval.error_msg = "String constant too long";
    return (ERROR);
  }
}

<str>\\t  push_char('\t');
<str>\\b  push_char('\b');
<str>\\n  push_char('\n');
<str>\\f  push_char('\f');
<str>\\.  push_char(yytext[1]);

<str>\\\n  curr_lineno++; push_char(yytext[1]);

<str>[^\\\n\"]+  {
  char *yptr = yytext;
  while (*yptr) {
    push_char(*yptr++);
  }
}

<str>\\?\n  {
  BEGIN(INITIAL);
  unput('\n');
  cool_yylval.error_msg = "Unterminated string constant";
  return (ERROR);
}

<str><<EOF>> {
  BEGIN(INITIAL);
  cool_yylval.error_msg = "EOF in string constant";
  return (ERROR);
}

 /* Invalid character for start of token  */

[^ \t\r\n\f\v]  {
  cool_yylval.error_msg = yytext;
  return (ERROR);
}

%%
