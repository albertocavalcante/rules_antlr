package org.antlr.bazel;

import static org.antlr.bazel.Language.*;
import static org.junit.Assert.assertEquals;

import org.antlr.bazel.Language;
import org.antlr.bazel.Namespace;
import org.junit.Test;


/**
 * Tests for {@link Language}.
 *
 * @author  Marco Hunsicker
 */
public class LanguageTest
{
    @Test(expected = IllegalArgumentException.class)
    public void invalid()
    {
        Language.of("Php");
    }


    @Test
    public void language()
    {
        assertEquals(C, Language.detect("grammar G2;\noptions{language=C ;}\nr : C;"));
        assertEquals(CPP, Language.detect("grammar G2;\noptions{language=Cpp;}\nr : C;"));
        assertEquals(CPP,
                Language.detect("grammar G2;\noptions { language = Cpp ; }\nr : C;"));
        assertEquals(CPP,
                Language.detect("grammar G2;\noptions {\n    language=Cpp;\n}\nr : C;"));
        assertEquals(CPP,
                Language.detect("grammar G2;\noptions{language=\nCpp;}\nr : C;"));
        assertEquals(CPP,
                Language.detect("grammar G2;\noptions{language\r\n=\rCpp;}\nr : C;"));
        assertEquals(CPP,
                Language.detect("grammar G2;\noptions{ language \r\n =\r \nCpp;}\nr : C;"));
        assertEquals(CSHARP,
                Language.detect("grammar G2;\noptions{language=CSharp ;}\nr : C;"));
        assertEquals(CSHARP,
                Language.detect("grammar G2;\noptions { language=CSharp2 ;}\nr : C;"));
        assertEquals(GO,
                Language.detect("grammar G2;\noptions{ language = Go; }\nr : C;"));
        assertEquals(JAVA, Language.detect("grammar G2;\nr : C;"));
        assertEquals(JAVA,
                Language.detect("grammar G2;\noptions{tokenVocab=SomeLexer;}\nr : C;"));
        assertEquals(JAVA,
                Language.detect("grammar G2;\noptions{language=Java ;}\nr : C;"));
        assertEquals(JAVASCRIPT,
                Language.detect("grammar G2;\noptions{language=JavaScript ;}\nr : C;"));
        assertEquals(OBJC,
                Language.detect("grammar G2;\noptions{language=ObjC;}\nr : C;"));
        assertEquals(PYTHON,
                Language.detect("grammar G2;\noptions{language=Python ;}\nr : C;"));
        assertEquals(PYTHON,
                Language.detect("grammar G2;\noptions{language=Python2 ;}\nr : C;"));
        assertEquals(PYTHON,
                Language.detect("grammar G2;\noptions{language=Python3 ;}\nr : C;"));
        assertEquals(RUBY,
                Language.detect("grammar G2;\noptions{language=Ruby ;}\nr : C;"));
        assertEquals(SWIFT,
                Language.detect("grammar G2;\noptions{language=Swift ;}\nr : C;"));
    }


    @Test
    public void layout()
    {
        assertEquals(".*[\\\\/]src[\\\\/]antlr[234]?[\\\\/](.*)",
                C.getLayout().toString());
        assertEquals(".*[\\\\/]src[\\\\/]antlr[234]?[\\\\/](.*)",
                CPP.getLayout().toString());
        assertEquals(".*[\\\\/]src[\\\\/]antlr[234]?[\\\\/](.*)",
                CSHARP.getLayout().toString());
        assertEquals("", GO.getLayout().toString());
        assertEquals(".*[\\\\/]src[\\\\/]main[\\\\/]antlr[234]?[\\\\/](.*)",
                JAVA.getLayout().toString());
        assertEquals(".*[\\\\/]src[\\\\/]antlr[234]?[\\\\/](.*)",
                JAVASCRIPT.getLayout().toString());
        assertEquals("", OBJC.getLayout().toString());
        assertEquals(".*[\\\\/]src[\\\\/]antlr[234]?[\\\\/](.*)",
                PYTHON.getLayout().toString());
        assertEquals("", SWIFT.getLayout().toString());
    }


    @Test
    public void namespace()
    {
        assertEquals(null, C.detectNamespace("struct foo { int a; };"));
        assertEquals(null, CPP.detectNamespace("grammar test;"));
        assertEquals(Namespace.of("A"), CPP.detectNamespace("@namespace{A}"));
        assertEquals(Namespace.of("A"), CPP.detectNamespace("@lexer::namespace {\n A\n }"));
        assertEquals(Namespace.of("A"), CPP.detectNamespace("@parser::namespace { A }"));

        assertEquals(null, CSHARP.detectNamespace("grammar test;"));
        assertEquals(Namespace.of("A"), CSHARP.detectNamespace("@namespace{A}"));
        assertEquals(Namespace.of("A"),
                CSHARP.detectNamespace("@lexer::namespace {\n A\n }"));
        assertEquals(Namespace.of("A"), CSHARP.detectNamespace("@parser::namespace { A }"));

        assertEquals(null, GO.detectNamespace("header {}"));
        assertEquals(null, GO.detectNamespace(""));
        assertEquals(Namespace.of("foo"), GO.detectNamespace("@header {\npackage foo\n}"));
        assertEquals(Namespace.of("foo"), GO.detectNamespace("@header { package foo }"));
        assertEquals(Namespace.of("foo"),
                GO.detectNamespace("@lexer::header {package foo}"));
        assertEquals(Namespace.of("foo"),
                GO.detectNamespace("@parser::header {package\nfoo}"));

        assertEquals(null, JAVA.detectNamespace(" "));
        assertEquals(null, JAVA.detectNamespace("header {}"));
        assertEquals(Namespace.of("foo"), JAVA.detectNamespace("header { package foo ; }"));
        assertEquals(Namespace.of("foo.bar"),
                JAVA.detectNamespace("header {package foo.bar;}"));
        assertEquals(Namespace.of("foo.bar"),
                JAVA.detectNamespace("header {package\nfoo.bar;}"));
        assertEquals(Namespace.of("org.antlr.v4.parse"), JAVA.detectNamespace("// @header test { comment }\n@lexer::header {\npackage org.antlr.v4.parse;\n}"));
        assertEquals(Namespace.of("org.antlr.v4.parse"), JAVA.detectNamespace("/* @header test { comment } */\n@lexer::header {\npackage org.antlr.v4.parse;\n}"));
        assertEquals(Namespace.of("org.antlr.v4.parse"), JAVA.detectNamespace("/*\n * @header test { comment }\n */\n@lexer::header {\npackage org.antlr.v4.parse;\n}"));

        assertEquals(null, OBJC.detectNamespace(""));

        assertEquals(null, PYTHON.detectNamespace("header \"Lexer.__main__\" {}"));
        assertEquals(null, RUBY.detectNamespace(""));
        assertEquals(null, RUBY.detectNamespace("header {}"));
        assertEquals(Namespace.of("Foo"), RUBY.detectNamespace("header {module Foo}"));
        assertEquals(null, SWIFT.detectNamespace(""));
    }
}
