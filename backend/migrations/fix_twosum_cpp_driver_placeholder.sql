UPDATE driver_code
SET
  driver_prefix = $$
#include <bits/stdc++.h>
using namespace std;

static vector<int> extractInts(istream& in) {
    vector<int> values;
    string line;
    while (getline(in, line)) {
        long long current = 0;
        int sign = 1;
        bool inNumber = false;
        for (char ch : line) {
            if (ch == '-' && !inNumber) {
                sign = -1;
                current = 0;
                inNumber = true;
                continue;
            }
            if (isdigit(static_cast<unsigned char>(ch))) {
                if (!inNumber) {
                    sign = 1;
                    current = 0;
                    inNumber = true;
                }
                current = current * 10 + (ch - '0');
            } else if (inNumber) {
                values.push_back(static_cast<int>(sign * current));
                sign = 1;
                current = 0;
                inNumber = false;
            }
        }
        if (inNumber) {
            values.push_back(static_cast<int>(sign * current));
        }
    }
    return values;
}
$$,
  driver_suffix = $$
int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    vector<int> parsed = extractInts(cin);
    if (parsed.size() < 2) {
        cout << "[]" << '\n';
        return 0;
    }

    int target = parsed.back();
    parsed.pop_back();
    vector<int> nums = parsed;

    Solution sol;
    vector<int> ans = sol.twoSum(nums, target);

    cout << "[";
    for (size_t i = 0; i < ans.size(); ++i) {
        if (i) cout << ",";
        cout << ans[i];
    }
    cout << "]" << '\n';
    return 0;
}
$$
WHERE problem_id = 1 AND language = 'cpp';
