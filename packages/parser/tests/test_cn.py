from openlex_parser.jurisdictions.cn import ChinaParser, cn_to_int

SAMPLE = """第三编 合同
第八章 违约责任
第五百七十七条 当事人一方不履行合同义务或者履行合同义务不符合约定的，应当承担继续履行、采取补救措施或者赔偿损失等违约责任。
"""


def test_cn_to_int():
    assert cn_to_int("五百七十七") == 577
    assert cn_to_int("十") == 10
    assert cn_to_int("一百零一") == 101
    assert cn_to_int("二十") == 20


def test_parse_tree():
    tree = ChinaParser().parse(SAMPLE.encode())
    article = tree[0].children[0].children[0]
    assert article.path == "p3/c8/a577"
    assert article.number_label == "第五百七十七条"
