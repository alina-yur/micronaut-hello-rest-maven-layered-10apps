package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloItalian extends BaseSingleLanguageApplication {

    private static final String GREETING = "Ciao";

    public static void main(String[] args) {
        launch(HelloItalian.class, args);
    }

    @Get(uri = "/hello/italian", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

