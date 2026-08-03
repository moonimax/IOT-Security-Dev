```
package b3nac.injuredandroid;
  
  
import android.os.Bundle;
  
import android.view.View;
  
import androidx.appcompat.widget.Toolbar;
  
import com.google.android.material.floatingactionbutton.FloatingActionButton;
  
import com.google.android.material.snackbar.Snackbar;
  
  
/* loaded from: classes.dex */
  
public class FlagTwoActivity extends androidx.appcompat.app.c {
  
    int w = 0;
  
  
    public /* synthetic */ void F(View view) {
  
        int i = this.w;
  
        if (i == 0) {
  
            Snackbar snackbarX = Snackbar.X(view, "Key words Activity and exported.", 0);
  
            snackbarX.Y("Action", null);
  
            snackbarX.N();
  
            this.w++;
  
            return;
  
        }
  
        if (i == 1) {
  
            Snackbar snackbarX2 = Snackbar.X(view, "Exported Activities can be accessed with adb or Drozer.", 0);
  
            snackbarX2.Y("Action", null);
  
            snackbarX2.N();
  
            this.w = 0;
  
        }
  
    }
  
  
    @Override // androidx.appcompat.app.c, androidx.fragment.app.d, androidx.activity.ComponentActivity, androidx.core.app.e, android.app.Activity
  
    protected void onCreate(Bundle bundle) {
  
        super.onCreate(bundle);
  
        setContentView(R.layout.activity_flag_two);
  
        C((Toolbar) findViewById(R.id.toolbar));
  
        ((FloatingActionButton) findViewById(R.id.fab)).setOnClickListener(new View.OnClickListener() { // from class: b3nac.injuredandroid.d
  
            @Override // android.view.View.OnClickListener
  
            public final void onClick(View view) {
  
                this.f.F(view);
  
            }
  
        });
  
    }
  
}
```