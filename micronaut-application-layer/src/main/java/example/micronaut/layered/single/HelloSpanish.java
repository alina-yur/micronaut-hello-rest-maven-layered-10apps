package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloSpanish extends BaseSingleLanguageApplication {

    private static final String GREETING = "Hola";

    public static void main(String[] args) {
        launch(HelloSpanish.class, args);
    }

    @Get(uri = "/hello/spanish", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

