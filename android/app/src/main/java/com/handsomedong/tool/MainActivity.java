package com.handsomedong.tool;

import android.os.Bundle;
import android.os.StrictMode;

import com.handsomedong.tool.utils.MyHttpClient;
import com.handsomedong.tool.utils.ShortVideoUtil;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import okhttp3.Response;

public class MainActivity extends FlutterActivity {
    private static final String channel = "parseShareLink";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
        StrictMode.setThreadPolicy(policy);

        new MethodChannel(Objects.requireNonNull(getFlutterEngine()).getDartExecutor().getBinaryMessenger(), channel).setMethodCallHandler(
                (methodCall, result) -> {
                    if (methodCall.method != null) {
                        result.success(ShortVideoUtil.getShortVideoDownloadUrl(methodCall.method));
                    } else {
                        result.notImplemented();
                    }
                }
        );
    }
}
