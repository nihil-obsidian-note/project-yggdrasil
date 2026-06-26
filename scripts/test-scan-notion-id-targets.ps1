Describe 'scan-notion-id-targets' {
    It 'detects md files with a trailing notion id' {
        $sampleNames = @(
            '룩스테라\설정\검은 광기 3c2b3b5aa6f64078bff4fce6cc8d5194.md',
            '룩스테라\템플릿\설정_국가 템플릿.md',
            '엘드로스 임시\설정\구버전 문서 11111111111111111111111111111111.md'
        )

        $matches = $sampleNames | Where-Object { $_ -match ' [0-9a-f]{32}\.md$' }
        $matches.Count | Should Be 2
    }

    It 'removes only the trailing notion id from a file path' {
        $renamed = '룩스테라\설정\검은 광기 3c2b3b5aa6f64078bff4fce6cc8d5194.md' -replace ' [0-9a-f]{32}(?=\.md$)', ''
        $renamed | Should Be '룩스테라\설정\검은 광기.md'
    }

    It 'can identify excluded temporary folders' {
        $isTemp = '엘드로스 임시\설정\구버전 문서 11111111111111111111111111111111.md' -like '엘드로스 임시*'
        $isTemp | Should Be $true
    }
}
