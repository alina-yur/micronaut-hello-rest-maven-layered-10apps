package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Controller;
import io.micronaut.http.annotation.Get;

@Controller
public final class HelloSwiss extends BaseSingleLanguageApplication {

    private static final String GREETING = "Grüezi";

    public static void main(String[] args) {
        launch(HelloSwiss.class, args);
    }

    @Get(uri = "/hello/swiss", produces = MediaType.TEXT_PLAIN)
    public String hello() {
        return GREETING;
    }

    @Override
    protected String greeting() {
        return GREETING;
    }
}

