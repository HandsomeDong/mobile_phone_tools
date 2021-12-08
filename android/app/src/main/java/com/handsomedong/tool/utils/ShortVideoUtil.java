package com.handsomedong.tool.utils;

import com.handsomedong.tool.video.ShareLinkParser;
import com.handsomedong.tool.video.impl.KuaiShouShareLinkParser;
import com.handsomedong.tool.video.impl.TikTokShareLinkParser;

import java.util.ArrayList;
import java.util.List;

public class ShortVideoUtil {
    public static List<ShareLinkParser> shareLinkParserList = new ArrayList<>();

    static {
        shareLinkParserList.add(new TikTokShareLinkParser());
        shareLinkParserList.add(new KuaiShouShareLinkParser());
    }

    public static String getShortVideoDownloadUrl(String shareText) {
        for (ShareLinkParser shareLinkParser : shareLinkParserList) {
            String shareLink = shareLinkParser.matchShareLink(shareText);
            if (shareLink != null) {
                return shareLinkParser.parse(shareLink);
            }
        }
        throw new RuntimeException("解析分享文本失败！请确认分享文本中存在分享链接！");
    }
}
