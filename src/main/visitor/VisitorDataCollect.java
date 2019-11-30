package main.visitor;

import main.ast.node.*;
import main.ast.node.Program;
import main.ast.node.declaration.*;
import main.ast.node.declaration.handler.*;
import main.ast.node.declaration.VarDeclaration;
import main.ast.node.expression.*;
import main.ast.node.expression.values.BooleanValue;
import main.ast.node.expression.values.IntValue;
import main.ast.node.expression.values.StringValue;
import main.ast.node.statement.*;
import main.symbolTable.SymbolTable;
import main.symbolTable.SymbolTableActorItem;
import main.symbolTable.SymbolTableHandlerItem;
import main.symbolTable.SymbolTableMainItem;
import main.symbolTable.itemException.ItemAlreadyExistsException;
import main.symbolTable.symbolTableVariableItem.SymbolTableActorVariableItem;

import java.util.ArrayList;

public class VisitorDataCollect implements Visitor {
    public static boolean hasError = false;
    @Override
    public void visit(Program program) {
        SymbolTable.root = new SymbolTable();

        ArrayList<ActorDeclaration> actors = program.getActors();
        for (ActorDeclaration x : actors) {
            x.accept(this);
        }
        Main main = program.getMain();
        main.accept((this));
    }

    @Override
    public void visit(ActorDeclaration actorDeclaration) {
        //TODO Remove print
        System.out.println(actorDeclaration.toString()+" "+actorDeclaration.getName().getName());

        SymbolTable.push(new SymbolTable(SymbolTable.top, actorDeclaration.toString()));

        SymbolTableActorItem actItem = new SymbolTableActorItem(actorDeclaration);
        actItem.setActorSymbolTable(SymbolTable.top);

        try {
            SymbolTable.root.put(actItem);
        } catch (ItemAlreadyExistsException e) {
            hasError = true;
            System.out.println("Line:" + actorDeclaration.getLine() + ":Redefinition of Actor " +
                    actorDeclaration.getName().getName());
        }

        Identifier name = actorDeclaration.getName();
        name.accept(this);

        Identifier par = actorDeclaration.getParentName();
        if (par != null)
        {
            actItem.setParentName(par.getName());
            par.accept(this);
        }

        // Checking duplicate known actors
        ArrayList<VarDeclaration> actors = actorDeclaration.getKnownActors();
        ArrayList<String> knowActorsName = new ArrayList<>();
        for (VarDeclaration actor : actors)
        {
            if(knowActorsName.contains(actor.getIdentifier().getName())) {
                hasError = true;
                System.out.println("Line:" + actor.getLine() + ":Redefinition of variable " + actor.getIdentifier().getName());
            }
            else
                knowActorsName.add(actor.getIdentifier().getName());
            actor.accept(this);
        }

        // Checking actor variables
        ArrayList<VarDeclaration> actor_vars = actorDeclaration.getActorVars();
        ArrayList<String> actorVarName = new ArrayList<>();
        for (VarDeclaration actor : actor_vars) {
            if(actorVarName.contains(actor.getIdentifier().getName())){
                hasError = true;
                System.out.println("Line:"+actor.getLine()+":Redefinition of variable " + actor.getIdentifier().getName());
            }
            else
                actorVarName.add(actor.getIdentifier().getName());
            actor.accept(this);
        }

        if (actorDeclaration.getInitHandler() != null)
            actorDeclaration.getInitHandler().accept(this);

        ArrayList<MsgHandlerDeclaration> msgs = actorDeclaration.getMsgHandlers();
        ArrayList<String> msgNames = new ArrayList<>();
        for (MsgHandlerDeclaration msg : msgs){
            if(msgNames.contains(msg.getName().getName()))
            {
                hasError = true;
                System.out.println("Line:"+msg.getLine()+"Redefinition of msghandler : " + msg.getName().getName());
            }
            else
                msgNames.add(msg.getName().getName());
            msg.accept(this);
        }
    }

    @Override
    public void visit(HandlerDeclaration handlerDeclaration) {
        handlerDeclaration.getName().accept(this);
        for (VarDeclaration arg : handlerDeclaration.getArgs())
            arg.accept(this);
        for (VarDeclaration var : handlerDeclaration.getLocalVars()) {

            var.accept(this);
        }
        for (Statement st : handlerDeclaration.getBody())
            st.accept(this);
    }

    @Override
    public void visit(VarDeclaration varDeclaration) {
//        System.out.println(varDeclaration.toString());
        varDeclaration.getType().accept(this);
        varDeclaration.getIdentifier().accept(this);
    }

    @Override
    public void visit(Main mainActors) {
        System.out.println(mainActors.toString());
        SymbolTable.push(new SymbolTable(SymbolTable.top, mainActors.toString()));
        SymbolTableMainItem mainItem = new SymbolTableMainItem(mainActors);
        mainItem.setMainSymbolTable(SymbolTable.top);
        try {
            SymbolTable.root.put(mainItem);
        } catch (ItemAlreadyExistsException e) {
//            e.printStackTrace();
        }

        ArrayList<ActorInstantiation> actors = mainActors.getMainActors();

        for (ActorInstantiation actor : actors) {
            SymbolTableActorVariableItem actItem = new SymbolTableActorVariableItem(actor);
            try{
                SymbolTable.top.put(actItem);
            } catch (ItemAlreadyExistsException e) {
                System.out.println("Line: " + actor.getLine() + ":Redefinition of actor instance " + actItem.getName());
            }
            actor.accept(this);
        }
        SymbolTable.pop();
    }

    @Override
    public void visit(ActorInstantiation actorInstantiation) {
//        System.out.println(actorInstantiation.toString());
        actorInstantiation.getIdentifier().accept(this);
        for (Identifier x : actorInstantiation.getKnownActors())
            x.accept(this);
        for (Expression x : actorInstantiation.getInitArgs())
            x.accept(this);
    }

    @Override
    public void visit(UnaryExpression unaryExpression) {
//        System.out.println(unaryExpression.toString());
        unaryExpression.getOperand().accept(this);
    }

    @Override
    public void visit(BinaryExpression binaryExpression) {
//        System.out.println(binaryExpression.toString());
        binaryExpression.getLeft().accept(this);
        binaryExpression.getRight().accept(this);
    }

    @Override
    public void visit(ArrayCall arrayCall) {
//        System.out.println(arrayCall.toString());
        arrayCall.getArrayInstance().accept(this);
        arrayCall.getIndex().accept(this);
    }

    @Override
    public void visit(ActorVarAccess actorVarAccess) {
//        System.out.println(actorVarAccess.toString());
        actorVarAccess.getSelf().accept(this);
        actorVarAccess.getVariable().accept(this);
    }

    @Override
    public void visit(Identifier identifier) {
//        System.out.println((identifier.toString()));
    }

    @Override
    public void visit(Self self) {
//        System.out.println(self.toString());
    }

    @Override
    public void visit(Sender sender) {
//        System.out.println(sender.toString());
    }

    @Override
    public void visit(BooleanValue value) {

//        System.out.println(value.toString());
    }

    @Override
    public void visit(IntValue value) {

//        System.out.println(value.toString());
    }

    @Override
    public void visit(StringValue value) {

//        System.out.println(value.toString());
    }

    @Override
    public void visit(Block block) {
//        System.out.println(block.toString());
        for (Statement st : block.getStatements())
            st.accept(this);
    }

    @Override
    public void visit(Conditional conditional) {
//        System.out.println(conditional.toString());
        conditional.getExpression().accept(this);
        conditional.getThenBody().accept(this);
        if (conditional.getElseBody() != null)
            conditional.getElseBody().accept(this);
    }

    @Override
    public void visit(For loop) {
//        System.out.println(loop.toString());
        loop.getInitialize().accept(this);
        loop.getCondition().accept(this);
        loop.getUpdate().accept(this);
        loop.getBody().accept(this);
    }

    @Override
    public void visit(Break breakLoop) {

//        System.out.println(breakLoop.toString());
    }

    @Override
    public void visit(Continue continueLoop) {

//        System.out.println(continueLoop.toString());
    }

    @Override
    public void visit(MsgHandlerCall msgHandlerCall) {
        msgHandlerCall.getInstance().accept(this);
        msgHandlerCall.getMsgHandlerName().accept(this);
        for (Expression ex : msgHandlerCall.getArgs())
            ex.accept(this);
    }

    @Override
    public void visit(Print print) {
        System.out.println(print.toString());
        print.getArg().accept(this);
    }

    @Override
    public void visit(Assign assign) {
        System.out.println(assign.toString());
        assign.getlValue().accept(this);
        assign.getrValue().accept(this);
    }
}
