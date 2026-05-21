package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloFrench extends BaseSingleLanguageApplication {

    private static final String GREETING = "Bonjour";

    public static void main(String[] args) {
        launch(HelloFrench.class, args);
    }

    @Get(uri = "/hello/french", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

