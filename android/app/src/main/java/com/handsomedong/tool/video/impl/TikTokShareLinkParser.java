package com.handsomedong.tool.video.impl;

import com.handsomedong.tool.utils.MyHttpClient;
import com.handsomedong.tool.utils.ShortVideoUtil;
import com.handsomedong.tool.video.ShareLinkParser;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import okhttp3.Response;

public class TikTokShareLinkParser implements ShareLinkParser {
    private static final Pattern shareLinkPattern = Pattern.compile("http[s]*:\\/\\/v.douyin.com\\/\\S+\\/");
    private static final Pattern redirectUrlPattern = Pattern.compile("^http[s]*:\\/\\/([\\w\\.\\d]+)\\/share\\/video\\/(\\d+)\\/");
    
    @Override
    public String matchShareLink(String shareText) {
        Matcher shareLinkMatcher = shareLinkPattern.matcher(shareText);
        String shareLink = null;
        if (shareLinkMatcher.find()) {
            shareLink = shareLinkMatcher.group(0);
        }
        return shareLink;
    }

    @Override
    public String parse(String shareLink) {
        Map<String, String> headers = new HashMap<>();
        headers.put("user-agent", "Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1");
        MyHttpClient httpClient = new MyHttpClient(shareLink, "GET", headers);
        httpClient.setClient(httpClient.getClient().newBuilder().followRedirects(false).build());
        // 先请求分享链接获取重定向链接
        Response response = httpClient.request();
        if (response.code() != 302) {
            throw new RuntimeException("请求分享链接失败！请稍后重试！");
        }
        String redirectUrl = response.header("location");
        if (redirectUrl == null) {
            throw new RuntimeException("获取重定向链接失败！请稍后重试！");
        }
        Matcher redirectUrlMatcher = redirectUrlPattern.matcher(redirectUrl);
        if (!redirectUrlMatcher.find()) {
            throw new RuntimeException("解析重定向链接失败！请稍后重试！");
        }
        
        // 重定向链接里面有视频id，用视频id拼凑成一个接口请求获取视频相关数据
        String host = redirectUrlMatcher.group(1);
        String itemId = redirectUrlMatcher.group(2);
        String videoInfoUrl = String.format("https://%s/web/api/v2/aweme/iteminfo/?item_ids=%s", host, itemId);
        httpClient.setUrl(videoInfoUrl);
        response = httpClient.request();
        JSONObject resultJson;
        try {
            String resStr = Objects.requireNonNull(response.body()).string();
            resultJson = new JSONObject(resStr);
            System.out.println(resStr);
        } catch (IOException e) {
            throw new RuntimeException("请求获取短视频数据失败！请稍后重试！");
        } catch (JSONException e) {
            throw new RuntimeException("解析短视频数据失败！请稍后重试！");
        }
        String videoDownloadUrl;
        try {
            videoDownloadUrl = resultJson.getJSONArray("item_list").getJSONObject(0).getJSONObject("video").getJSONObject("play_addr").getJSONArray("url_list").getString(0);
        } catch (JSONException e) {
            e.printStackTrace();
            throw new RuntimeException("解析短视频JSON数据失败！请稍后重试！");
        }
        return videoDownloadUrl;
    }
}
