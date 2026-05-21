package example.micronaut.layered.single;

import io.micronaut.http.MediaType;
import io.micronaut.http.annotation.Get;
import io.micronaut.runtime.Micronaut;

public abstract class BaseSingleLanguageApplication {

    protected static void launch(Class<?> applicationClass, String[] args) {
        Micronaut.run(applicationClass, args);
    }

    @Get(uri = "/", produces = MediaType.TEXT_PLAIN)
    public String index() {
        return greeting();
    }

    protected abstract String greeting();
}

