package example.micronaut.baselayer;

import java.lang.reflect.Array;
import java.lang.reflect.Method;
import java.sql.Date;
import java.sql.Time;
import java.sql.Timestamp;

import org.graalvm.nativeimage.hosted.Feature;

import com.oracle.svm.sdk.staging.hosted.layeredimage.LayeredCompilationSupport;
import com.oracle.svm.sdk.staging.layeredimage.LayeredCompilationBehavior.Behavior;

/**
 * Pins reflective array helpers into the initial layer so later application layers
 * do not discover Graal's substituted Array support for the first time.
 */
public final class ReflectArrayInitialLayerFeature implements Feature {

    @Override
    public void afterRegistration(AfterRegistrationAccess access) {
        for (Method method : Array.class.getDeclaredMethods()) {
            LayeredCompilationSupport.singleton().registerCompilationBehavior(method, Behavior.PINNED_TO_INITIAL_LAYER);
        }
    }

    @Override
    public void beforeAnalysis(BeforeAnalysisAccess access) {
        access.registerAsUsed(Array.class);
        access.registerAsUsed(Date.class);
        access.registerAsUsed(Time.class);
        access.registerAsUsed(Timestamp.class);
    }
}
