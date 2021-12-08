package com.handsomedong.tool.video.impl;

import com.handsomedong.tool.utils.MyHttpClient;
import com.handsomedong.tool.video.ShareLinkParser;

import org.json.JSONObject;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import okhttp3.Response;

public class KuaiShouShareLinkParser implements ShareLinkParser {
    private static final Pattern shareLinkPattern = Pattern.compile("http[s]*:\\/\\/v.kuaishou.com\\/\\S+");


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
        headers.put("user-agent", "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.45 Mobile Safari/537.36");
        headers.put("accept", "*/*");
        MyHttpClient httpClient = new MyHttpClient(shareLink, "GET", headers);
        Response response = httpClient.request();
        if (response.code() != 200) {
            throw new RuntimeException("请求分享链接失败！请稍后重试！");
        }
        try {
            String html = Objects.requireNonNull(response.body()).string();
            Document document = Jsoup.parse(html);
            return Objects.requireNonNull(document.getElementById("video-player")).attr("src");
        } catch (Exception e) {
            throw new RuntimeException("解析数据失败！" + e.getMessage());
        }
    }
}
