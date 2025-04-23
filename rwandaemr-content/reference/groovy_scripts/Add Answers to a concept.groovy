import java.util.*;
import org.openmrs.*;
import org.openmrs.api.*;
import org.openmrs.api.context.Context;

Concept consu=Context.getConceptService().getConcept(9630);
for (i=113399;i<=113889;i++) {
   consu.addAnswer(new ConceptAnswer(Context.getConceptService().getConcept(i)));
}
Context.getConceptService().saveConcept(consu);

/* Concept consu=Context.getConceptService().getConcept(9630);
for (ConceptAnswer ca:consu.getAnswers()) {
   if (ca.getAnswerConcept()==null){
         consu.removeAnswer(ca);
       println(ca.getConceptAnswerId())
        break;

}      
}*/


​