package com.handsomedong.tool;

import android.os.Bundle;
import android.os.StrictMode;

import com.handsomedong.tool.utils.MyHttpClient;

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
    private static final Pattern shareLinkPattern = Pattern.compile("http[s]*:\\/\\/v.douyin.com\\/.+\\/");
    private static final Pattern redirectUrlPattern = Pattern.compile("^http[s]*:\\/\\/([\\w\\.\\d]+)\\/share\\/video\\/(\\d+)\\/");

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
        StrictMode.setThreadPolicy(policy);

        new MethodChannel(getFlutterEngine().getDartExecutor().getBinaryMessenger(), channel).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        if (methodCall.method != null) {
                            result.success(parseShareLink(methodCall.method));
                        } else {
                            result.notImplemented();
                        }
                    }
                }
        );
    }


    public String parseShareLink(String shareText) {
        Matcher shareLinkMatcher = shareLinkPattern.matcher(shareText);
        String shareLink = "";
        if (shareLinkMatcher.find()) {
            shareLink = shareLinkMatcher.group(0);
        } else {
            return "解析分享链接失败！";
        }

        Map<String, String> headers = new HashMap<>();
        headers.put("user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1");
        MyHttpClient httpClient = new MyHttpClient(shareLink, "GET", headers);
        httpClient.setClient(httpClient.getClient().newBuilder().followRedirects(false).build());
        Response response = httpClient.request();
        if (response.code() != 302) {
            return "请求分享链接失败";
        }


        String redirectUrl = response.header("location");
        if (redirectUrl == null) {
            return "获取重定向链接失败";
        }
        String host = "";
        String itemId = "";
        Matcher redirectUrlMatcher = redirectUrlPattern.matcher(redirectUrl);
        if (redirectUrlMatcher.find()) {
            host = redirectUrlMatcher.group(1);
            itemId = redirectUrlMatcher.group(2);
        } else {
            return "解析重定向链接失败！";
        }
        String videoInfoUrl = String.format("https://%s/web/api/v2/aweme/iteminfo/?item_ids=%s", host, itemId);
        httpClient.setUrl(videoInfoUrl);
        response = httpClient.request();
        JSONObject resultJson;
        try {
            String resStr = Objects.requireNonNull(response.body()).string();
            resultJson = new JSONObject(resStr);
            System.out.println(resStr);
        } catch (IOException e) {
            e.printStackTrace();
            return "请求获取短视频数据失败！";
        } catch (JSONException e) {
            e.printStackTrace();
            return "解析短视频数据失败！";
        }
        String videoDownloadUrl;
        try {
            videoDownloadUrl = resultJson.getJSONArray("item_list").getJSONObject(0).getJSONObject("video").getJSONObject("play_addr").getJSONArray("url_list").getString(0);
        } catch (JSONException e) {
            e.printStackTrace();
            return "解析短视频JSON数据失败！";
        }

        return videoDownloadUrl;
    }
}
