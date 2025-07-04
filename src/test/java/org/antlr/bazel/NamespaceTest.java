package org.antlr.bazel;

import java.nio.file.Paths;

import com.google.common.testing.EqualsTester;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertTrue;

import org.antlr.bazel.Language;
import org.antlr.bazel.Namespace;
import org.junit.Test;


/**
 * Tests for {@link Namespace}.
 *
 * @author  Marco Hunsicker
 */
public class NamespaceTest
{
    @Test
    public void equals()
    {
        Namespace empty1 = Namespace.of("");
        Namespace empty2 = Namespace.of("");
        Namespace namespaceA = Namespace.of("a");
        Namespace namespaceB = Namespace.of("b");
        
        new EqualsTester()
                .addEqualityGroup(empty1, empty2)
                .addEqualityGroup(namespaceA)
                .addEqualityGroup(namespaceB)
                .addEqualityGroup("different type")
                .testEquals();
    }


    @Test
    public void hashcode()
    {
        assertEquals(31 + "".hashCode(), Namespace.of("").hashCode());
    }


    @Test
    public void isEmpty()
    {
        assertTrue(Namespace.of("").isEmpty());
        assertFalse(Namespace.of("a").isEmpty());
    }


    @Test
    public void isHeader()
    {
        assertTrue(Namespace.of("foo.bar", true).isHeader());
        assertFalse(Namespace.of("foo.bar").isHeader());
    }


    @Test
    public void of()
    {
        assertEquals("org::antlr::test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.CPP).toString());
        assertEquals("org.antlr.test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.CSHARP).toString());
        assertEquals("org/antlr/test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.GO).toString());
        assertEquals("org.antlr.test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.JAVA).toString());
        assertEquals("org/antlr/test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.JAVASCRIPT).toString());
        assertEquals("org\\antlr/test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.OBJC).toString());
        assertEquals("org/antlr/test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.PYTHON).toString());
        assertEquals("org::antlr::test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.RUBY).toString());
        assertEquals("org.antlr.test",
                Namespace.of(Paths.get("org\\antlr/test"), Language.SWIFT).toString());
    }


    @Test
    public void toPath()
    {
        assertEquals("org/antlr/test",
                Namespace.of("org::antlr::test").toPath(Language.CPP));
        assertEquals("org/antlr/test",
                Namespace.of("org.antlr.test").toPath(Language.CSHARP));
        assertEquals("org/antlr/test",
                Namespace.of("org/antlr/test").toPath(Language.GO));
        assertEquals("org/antlr/test",
                Namespace.of("org.antlr.test").toPath(Language.JAVA));
        assertEquals("org/antlr/test",
                Namespace.of("org/antlr/test").toPath(Language.JAVASCRIPT));
        assertEquals("org/antlr/test",
                Namespace.of("org/antlr/test").toPath(Language.OBJC));
        assertEquals("org/antlr/test",
                Namespace.of("org.antlr.test").toPath(Language.PYTHON));
        assertEquals("org/antlr/test",
                Namespace.of("org::antlr::test").toPath(Language.RUBY));
        assertEquals("org/antlr/test",
                Namespace.of("org.antlr.test").toPath(Language.SWIFT));
    }
}
