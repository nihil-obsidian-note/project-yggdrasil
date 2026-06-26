Describe 'rewrite-notion-id-links' {
    It 'removes ids from markdown link targets' {
        $decodedTarget = [Uri]::UnescapeDataString('%EB%B0%9C%EA%B0%80%EB%A5%B4%20%EB%8C%80%EB%A5%99%2033a3ce531dea804fbdcef13f1d6595ef.md')
        ($decodedTarget -replace ' [0-9a-f]{32}(?=\.md$)', '') | Should Be '발가르 대륙.md'
    }

    It 'supports notion url replacement targets' {
        $mapped = '[컬트 오브 디스페어](../설정/컬트 오브 디스페어.md)'
        $mapped | Should Be '[컬트 오브 디스페어](../설정/컬트 오브 디스페어.md)'
    }

    It 'removes ids from wiki links' {
        $wiki = '[[발가르 대륙 33a3ce531dea804fbdcef13f1d6595ef]]'
        ($wiki -replace ' [0-9a-f]{32}(?=\]\])', '') | Should Be '[[발가르 대륙]]'
    }
}
