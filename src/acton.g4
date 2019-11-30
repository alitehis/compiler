grammar acton;

@header {
    import main.*;
    //import main.ast.*;
    import main.ast.node.*;
    import main.ast.node.declaration.*;
    import main.ast.node.declaration.handler.*;
    import main.ast.node.expression.*;
    import main.ast.node.expression.operators.*;
    import main.ast.node.expression.values.*;
    import main.ast.node.statement.*;
    import main.ast.type.*;
    import main.ast.type.actorType.*;
    import main.ast.type.arrayType.*;
    import main.ast.type.primitiveType.*;
    import java.util.ArrayList;
}

program
	returns[Program p]:{
	    $p = new Program();
	} (x1=actorDeclaration{
	    $p.addActor($x1.ret);
	})+ x2=mainDeclaration{
	    $p.setMain($x2.ret);
	};

actorDeclaration returns[ActorDeclaration ret]:
	t = ACTOR x=identifier
	{
	    $ret = new ActorDeclaration($x.ret);
	    $ret.setLine($t.getLine());
	}
	(EXTENDS y=identifier
	{
        $ret.setParentName($y.ret);
	}
	)? LPAREN z=INTVAL
	{
        $ret.setQueueSize($z.int);
	} RPAREN LBRACE (
		KNOWNACTORS LBRACE (f=identifier g=identifier SEMICOLON
		{
            VarDeclaration knownActor = new VarDeclaration($g.ret, new ActorType($f.ret));
            knownActor.setLine($f.ret.getLine());
		    $ret.addKnownActor(knownActor);
		})* RBRACE
	) (ACTORVARS LBRACE h=varDeclarations RBRACE)
	{
	    if($h.ret != null)
	        $ret.setActorVars($h.ret);
	}
	( i = initHandlerDeclaration
	{
	    $ret.setInitHandler($i.ret);
	})?
	(k=msgHandlerDeclaration
	 {
	    $ret.addMsgHandler($k.ret);
	 })* RBRACE;

mainDeclaration returns[Main ret]:{
    $ret = new Main();
} t = MAIN {$ret.setLine($t.getLine());} LBRACE (x1=actorInstantiation{
    $ret.addActorInstantiation($x1.ret);
})* RBRACE;

actorInstantiation returns[ActorInstantiation ret]:
	x1=identifier x2=identifier{
        $ret = new ActorInstantiation(new ActorType($x1.ret), $x2.ret);
	} t = LPAREN (
		x3=identifier
		{
		    $ret.setLine($t.getLine());
		    $ret.addKnownActor($x3.ret);
		} (COMMA x4=identifier{
		    $ret.addKnownActor($x4.ret);
		})*
		|
	) RPAREN COLON LPAREN x5=expressionList{
	    $ret.setInitArgs($x5.ret);
	} RPAREN SEMICOLON;

initHandlerDeclaration returns[InitHandlerDeclaration ret]:
    t=MSGHANDLER x0=INITIAL{
        $ret = new InitHandlerDeclaration(new Identifier($x0.text));
        $ret.setLine($t.getLine());
    } LPAREN x1=argDeclarations{
        $ret.setArgs($x1.ret);
	} RPAREN LBRACE x2=varDeclarations{
        $ret.setLocalVars($x2.ret);
	} (
		x3=statement{
            $ret.addStatement($x3.ret);
		}
	)* RBRACE;

msgHandlerDeclaration returns[MsgHandlerDeclaration ret]:
	t=MSGHANDLER x1=identifier{
	    $ret = new MsgHandlerDeclaration($x1.ret);
	    $ret.setLine($t.getLine());
	} LPAREN x2=argDeclarations{
	    $ret.setArgs($x2.ret);
	} RPAREN LBRACE x3=varDeclarations{
	    $ret.setLocalVars($x3.ret);
	}
	(
		x4=statement{
		    $ret.addStatement($x4.ret);
		}
	)* RBRACE;

argDeclarations returns[ArrayList<VarDeclaration> ret]:
    {$ret = new ArrayList<VarDeclaration>();}
    x1=varDeclaration {
        $ret.add($x1.ret);
    } (COMMA x2=varDeclaration{
        $ret.add($x2.ret);
    })* |{
        $ret = new ArrayList<VarDeclaration>();
    };

varDeclarations returns[ArrayList<VarDeclaration> ret]:
    {
        $ret = new ArrayList<VarDeclaration>();
    }
    (x1=varDeclaration SEMICOLON{
    $ret.add($x1.ret);
})*;

varDeclaration returns[VarDeclaration ret]:
	t1=INT x1=identifier{
	    $ret = new VarDeclaration($x1.ret, new IntType());
        $ret.setLine($t1.getLine());
	}
	| t2=STRING x2=identifier{
	    $ret = new VarDeclaration($x2.ret, new StringType());
        $ret.setLine($t2.getLine());
	}
	| t3=BOOLEAN x3=identifier{
	    $ret = new VarDeclaration($x3.ret, new BooleanType());
	    $ret.setLine($t3.getLine());
	}
	| t4=INT x4=identifier LBRACKET y=INTVAL RBRACKET{
   	    $ret = new VarDeclaration($x4.ret, new ArrayType($y.int));
        $ret.setLine($t4.getLine());
	};

statement returns[Statement ret]:
    x1=blockStmt{
        $ret = $x1.ret;
    }
	|   x2=printStmt{
        $ret = $x2.ret;
    }
	|   x3=assignStmt{
        $ret = $x3.ret;
	}
	|   x4=forStmt{
        $ret = $x4.ret;
	}
	|   x5=ifStmt{
        $ret = $x5.ret;
	}
	|   x6=continueStmt{
        $ret = $x6.ret;
	}
	|   x7=breakStmt{
        $ret = $x7.ret;
	}
	|   x8=msgHandlerCall{
        $ret = $x8.ret;
};

blockStmt returns[Block ret]: {
    $ret = new Block();
} t=LBRACE {$ret.setLine($t.getLine());} (s=statement
{
    $ret.addStatement($s.ret);
})* RBRACE;

printStmt returns[Print ret]: t=PRINT LPAREN e=expression
{
    $ret = new Print($e.ret);
    $ret.setLine($t.getLine());
}RPAREN SEMICOLON;

assignStmt returns[Statement ret]: x1=assignment SEMICOLON{
    $ret = $x1.ret;
};

assignment returns[Assign ret]: x1=orExpression t=ASSIGN x2=expression{
    $ret = new Assign($x1.ret, $x2.ret);
    $ret.setLine($t.getLine());
};

forStmt returns[For ret]:
    {
        $ret = new For();
    }
	t=FOR {$ret.setLine($t.getLine());} LPAREN (x1=assignment{
	    $ret.setInitialize($x1.ret);
	})? SEMICOLON (x2=expression{
	    $ret.setCondition($x2.ret);
	})? SEMICOLON (
		x3=assignment{
		    $ret.setUpdate($x3.ret);
		}
	)? RPAREN x4=statement{
	    $ret.setBody($x4.ret);
	};

ifStmt returns[Conditional ret]:
    t=IF LPAREN x1=expression RPAREN x2=statement x3=elseStmt
    {
        $ret = new Conditional($x1.ret, $x2.ret);
        $ret.setLine($t.getLine());
        if($x2.ret != null)
            $ret.setElseBody($x3.ret);
    }
    ;

elseStmt returns[Statement ret]: ELSE x1=statement{
    $ret = $x1.ret;
} |{
    $ret = null;
};

continueStmt returns[Continue ret]: t=CONTINUE SEMICOLON{
    $ret = new Continue();
    $ret.setLine($t.getLine());
};

breakStmt returns[Break ret]: t=BREAK SEMICOLON{
    $ret = new Break();
    $ret.setLine($t.getLine());
};

msgHandlerCall returns[MsgHandlerCall ret] locals[Expression ex]:
    (x1=identifier{$ex = $x1.ret;} | x4=SELF{$ex = new Self();} | x5=SENDER{$ex = new Sender();})
     t=DOT x2=identifier LPAREN x3=expressionList RPAREN SEMICOLON
    {
        $ret = new MsgHandlerCall($ex, $x2.ret);
        $ret.setLine($t.getLine());
        $ret.setArgs($x3.ret);
    };

expression returns[Expression ret]:
    x1=orExpression{
        $ret = $x1.ret;
    } (t=ASSIGN x2=expression{
        $ret = new BinaryExpression($ret, $x2.ret, BinaryOperator.assign);
        $ret.setLine($t.getLine());
    })?;

orExpression returns [Expression ret]:
    x1=andExpression{
        $ret = $x1.ret;
    } (t=OR x2=andExpression{
        $ret = new BinaryExpression($ret, $x2.ret, BinaryOperator.or);
        $ret.setLine($t.getLine());
    })*;

andExpression returns [Expression ret]:
    x1=equalityExpression{
        $ret = $x1.ret;
    } (t=AND x2=equalityExpression{
        $ret = new BinaryExpression($ret, $x2.ret, BinaryOperator.and);
        $ret.setLine($t.getLine());
    })*;

equalityExpression returns [Expression ret] locals[BinaryOperator op]:
	x1=relationalExpression{
        $ret = $x1.ret;
	} ((op1=EQ{$op = BinaryOperator.eq;} | op2=NEQ{$op = BinaryOperator.neq;}) x2=relationalExpression{
        $ret = new BinaryExpression($ret, $x2.ret, $op);
        if($op1 != null)
            $ret.setLine($op1.getLine());
        else if($op2 != null)
            $ret.setLine($op2.getLine());
	})*;

relationalExpression returns [Expression ret] locals[BinaryOperator op]:
	x1=additiveExpression{
        $ret = $x1.ret;
    } ((op1=LT{$op = BinaryOperator.lt;} | op2=GT{$op = BinaryOperator.gt;}) x2=additiveExpression{
        $ret = new BinaryExpression($ret, $x2.ret, $op);
        if($op1 != null)
            $ret.setLine($op1.getLine());
        else if($op2 != null)
            $ret.setLine($op2.getLine());
    })*;

additiveExpression returns [Expression ret] locals[BinaryOperator op]:
	x1=multiplicativeExpression{
	     $ret = $x1.ret;
	} (
		(op1=PLUS{$op = BinaryOperator.add;} | op2=MINUS{$op = BinaryOperator.sub;}) x2=multiplicativeExpression{
            $ret = new BinaryExpression($ret, $x2.ret, $op);
            if($op1!= null)
                $ret.setLine($op1.getLine());
            else if($op2 != null)
                $ret.setLine($op2.getLine());
		}
	)*;

multiplicativeExpression returns [Expression ret] locals[BinaryOperator op]:
	x1=preUnaryExpression{
	    $ret = $x1.ret;
	} ((op1=MULT{$op = BinaryOperator.mult;} | op2=DIV{$op = BinaryOperator.div;} | op3=PERCENT{$op = BinaryOperator.mod;})
	x2=preUnaryExpression{
        $ret = new BinaryExpression($ret, $x2.ret, $op);
        if($op1 != null)
            $ret.setLine($op1.getLine());
        else if($op2 != null)
            $ret.setLine($op2.getLine());
	    else if($op3 != null)
	        $ret.setLine($op3.getLine());
	})*;

preUnaryExpression returns[Expression ret]:
	t=NOT exp1 = preUnaryExpression{
        $ret = new UnaryExpression(UnaryOperator.not, $exp1.ret);
	    $ret.setLine($t.getLine());
	}
	| t=MINUS exp2 = preUnaryExpression{
        $ret = new UnaryExpression(UnaryOperator.minus, $exp2.ret);
	    $ret.setLine($t.getLine());
	}
	| t=PLUSPLUS exp3 = preUnaryExpression{
        $ret = new UnaryExpression(UnaryOperator.preinc, $exp3.ret);
	    $ret.setLine($t.getLine());
	}
	| t=MINUSMINUS exp4 = preUnaryExpression{
        $ret = new UnaryExpression(UnaryOperator.predec, $exp4.ret);
	    $ret.setLine($t.getLine());
	}
	| exp5 = postUnaryExpression{
        $ret = $exp5.ret;
	};

postUnaryExpression
    returns[Expression ret]:
    exp =otherExpression{
        $ret = $exp.ret;
    } ( op = postUnaryOp {
        $ret = new UnaryExpression($op.ret, $exp.ret);
    })?;

postUnaryOp
    returns[UnaryOperator ret]:
    PLUSPLUS{
        $ret = UnaryOperator.postinc;
    } | MINUSMINUS{
        $ret = UnaryOperator.postdec;
    };

otherExpression
	returns[Expression ret]:
	LPAREN exp = expression RPAREN {
		$ret = $exp.ret;
	}
	| idf = identifier {
		$ret = $idf.ret;
	}
	| arc = arrayCall {
		$ret = $arc.ret;
	}
	| actVar = actorVarAccess {
		$ret = $actVar.ret;
	}
	| val = value {
		$ret = $val.ret;
	}
	| sender = SENDER {
		$ret = new Sender();
		$ret.setLine($sender.getLine());
	};

arrayCall returns[ArrayCall ret]: (x1=identifier | x2=actorVarAccess) t=LBRACKET x3=expression RBRACKET{
    if($x1.ret != null)
        $ret = new ArrayCall($x1.ret, $x3.ret);
    else
        $ret = new ArrayCall($x2.ret, $x3.ret);
    $ret.setLine($t.getLine());
};

actorVarAccess
	returns[Expression ret]:
	t=SELF DOT idf = identifier {
		$ret = new ActorVarAccess($idf.ret);
        $ret.setLine($t.getLine());
    };

expressionList returns[ArrayList<Expression> ret]:
{
    $ret = new ArrayList<Expression>();
}
    (
        x1=expression{$ret.add($x1.ret);}
        (
            COMMA x2=expression
            {
                $ret.add($x2.ret);
            }
        )* |
    );

identifier
	returns[Identifier ret]:
	IDENTIFIER {
        $ret = new Identifier($IDENTIFIER.text);
        $ret.setLine($IDENTIFIER.getLine());
    };

value
	returns[Value ret]:
	INTVAL {
        $ret = new IntValue($INTVAL.int, new IntType());
        $ret.setLine($INTVAL.getLine());
    }
	| STRINGVAL {
        $ret = new StringValue($STRINGVAL.text, new StringType());
        $ret.setLine($STRINGVAL.getLine());
    }
	| t1=TRUE {
        $ret = new BooleanValue(true, new BooleanType());
        $ret.setLine($t1.getLine());
    }
	| t2=FALSE {
        $ret = new BooleanValue(false, new BooleanType());
        $ret.setLine($t2.getLine());
    };

// values
INTVAL: [1-9][0-9]* | [0];

STRINGVAL: '"' ~["]* '"';

TRUE: 'true';

FALSE: 'false';

//types
INT: 'int';

BOOLEAN: 'boolean';

STRING: 'string';

//keywords
ACTOR: 'actor';

EXTENDS: 'extends';

ACTORVARS: 'actorvars';

KNOWNACTORS: 'knownactors';

INITIAL: 'initial';

MSGHANDLER: 'msghandler';

SENDER: 'sender';

SELF: 'self';

MAIN: 'main';

FOR: 'for';

CONTINUE: 'continue';

BREAK: 'break';

IF: 'if';

ELSE: 'else';

PRINT: 'print';

//symbols
LPAREN: '(';

RPAREN: ')';

LBRACE: '{';

RBRACE: '}';

LBRACKET: '[';

RBRACKET: ']';

COLON: ':';

SEMICOLON: ';';

COMMA: ',';

DOT: '.';

//operators
ASSIGN: '=';

EQ: '==';

NEQ: '!=';

GT: '>';

LT: '<';

PLUSPLUS: '++';

MINUSMINUS: '--';

PLUS: '+';

MINUS: '-';

MULT: '*';

DIV: '/';

PERCENT: '%';

NOT: '!';

AND: '&&';

OR: '||';

QUES: '?';

IDENTIFIER: [a-zA-Z_][a-zA-Z0-9_]*;

COMMENT: '//' ~[\n\r]* -> skip;

WHITESPACE: [ \t\r\n] -> skip;