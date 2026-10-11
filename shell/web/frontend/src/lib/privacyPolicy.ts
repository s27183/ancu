// Mai An Cư's privacy policy, in both languages (behavior 62), shown by PrivacySheet.
//
// Bilingual -> P-7 · One declaration per outcome shape -> The web frontend -> the privacy policy text
// Adapted 2026-10-11 from zi's policy (bigsmall-jsc/zi, web/src/routes/privacy, b6bc821,
// sent by zi-attended). Kept: the commitments (no AI training, no selling, no ads), the
// security and rights sections. Cut: OpenAI and Google Vertex (maiancu calls Anthropic
// alone — grep of engine/ and shell/, 2026-10-11), BaZi birth data, the 90-day chat keep,
// in-app account deletion (maiancu has none: rights go through info@maiancu.com).
// Added: Google sign-in (scope "openid email", fh_shell_h_auth), plan and property data,
// guest plans kept 7 days (fh_shell_guest ttl), the client address the daily plan cap
// reads, Resend for sign-in email, Cloudflare Pages and DigitalOcean Sydney (deployment.md).
// Not lawyer-reviewed; the wording is Son's to judge (behavior 62, Expect 6).
// Every fact here is a fact about the code: change the code, change this text.

export interface PolicySection {
    h: string;
    p?: string[];
    items?: string[];
}

export interface Policy {
    title: string;
    effective: string;
    intro: string;
    sections: PolicySection[];
}

export const PRIVACY: Record<'vi' | 'en', Policy> = {
    en: {
        title: 'Privacy policy',
        effective: 'Effective 11 October 2026',
        intro:
            'Mai An Cư (“we”, “us”) helps you plan buying, holding and selling a property in Australia. This policy explains what personal data we collect when you use maiancu.com, how we use and share it, how long we keep it, and the choices you have.',
        sections: [
            {
                h: 'Our commitments',
                items: [
                    'Your data is never used to train AI models — ours or our AI provider’s.',
                    'We never sell your data and never use it for advertising.',
                    'We collect only what the plan needs.',
                    'You can ask us to show, correct, export or delete your data at any time.'
                ]
            },
            {
                h: '1. What we collect',
                items: [
                    'Account: your email address. With Google sign-in we receive only your email address — not your name, contacts or other Google data.',
                    'Your plan: what you enter to build it — for example your budget, income, savings, loan details, visa or residency status, the state and suburbs you look at, and properties you attach.',
                    'Documents you upload for a property (such as a lease), so the plan can read them.',
                    'Questions you ask the AI assistant and its answers, kept with your plan.',
                    'Technical data: your IP address (to apply the daily limit on new plans and to protect the service), browser type and error logs.',
                    'Usage counts: how many plans and AI questions you used, to apply the free allowance.'
                ]
            },
            {
                h: '2. Cookies and storage on your device',
                p: [
                    'We use one sign-in cookie to keep you signed in, and a short-lived cookie during Google sign-in. Your browser also remembers your language and whether you have seen the welcome guide. We use no advertising or tracking cookies and no analytics service.'
                ]
            },
            {
                h: '3. How we use your data',
                items: [
                    'To build your plan and keep it up to date',
                    'To answer your questions about your plan',
                    'To sign you in and send sign-in emails',
                    'To apply the free allowance and protect the service from abuse',
                    'To meet legal obligations'
                ]
            },
            {
                h: '4. Who processes your data for us',
                items: [
                    'Anthropic — the AI model that builds parts of your plan and answers your questions. It receives the plan details and questions needed for that answer, and does not train its models on this data.',
                    'DigitalOcean — our servers and database, in Sydney, Australia.',
                    'Cloudflare — serves the website and protects it from attacks.',
                    'Resend — sends sign-in emails to your address.',
                    'Google — only if you choose to sign in with Google.'
                ],
                p: [
                    'We share data with no one else, except when the law, a court or the protection of someone’s safety requires it.'
                ]
            },
            {
                h: '5. How long we keep it',
                items: [
                    'A plan built without signing in: 7 days, then deleted. Sign in from the same browser within those 7 days to keep it in your account.',
                    'Your account, plans, documents and questions: until you ask us to delete them.',
                    'Daily counts for the plan limit, with the IP address they are kept under: deleted after 7 days.'
                ],
                p: [
                    'When you ask us to delete your account, we delete your data within 30 days, unless the law requires us to keep part of it.'
                ]
            },
            {
                h: '6. Security',
                p: [
                    'Data travels over encrypted connections (HTTPS). Sign-in uses one-time email links or Google, with no passwords stored. Access to our database is limited to the people who run the service.'
                ]
            },
            {
                h: '7. Your rights',
                items: [
                    'See the personal data we hold about you',
                    'Correct it',
                    'Receive a copy of it',
                    'Have your account and data deleted',
                    'Withdraw your consent, by stopping use and asking us to delete your data'
                ],
                p: ['Email info@maiancu.com from the address you sign in with, and we will reply.']
            },
            {
                h: '8. Where your data is processed',
                p: [
                    'Our servers are in Australia. Our AI provider and email provider may process data in other countries, such as the United States. Data you send from Vietnam is transferred to Australia to provide the service.'
                ]
            },
            {
                h: '9. Children',
                p: ['Mai An Cư is for adults planning a property purchase. It is not intended for anyone under 18.']
            },
            {
                h: '10. Changes',
                p: [
                    'If we change this policy, we will update the date above and tell you in the app when the change matters.'
                ]
            },
            {
                h: '11. Contact',
                p: ['Questions about this policy or your data: info@maiancu.com']
            }
        ]
    },
    vi: {
        title: 'Chính sách quyền riêng tư',
        effective: 'Có hiệu lực từ ngày 11 tháng 10 năm 2026',
        intro:
            'Mai An Cư (“chúng tôi”) giúp bạn lập kế hoạch mua, giữ và bán bất động sản tại Úc. Chính sách này giải thích chúng tôi thu thập những dữ liệu cá nhân nào khi bạn dùng maiancu.com, cách chúng tôi sử dụng và chia sẻ, thời gian lưu giữ, và các lựa chọn của bạn.',
        sections: [
            {
                h: 'Cam kết của chúng tôi',
                items: [
                    'Dữ liệu của bạn không bao giờ được dùng để huấn luyện mô hình AI — của chúng tôi hay của nhà cung cấp AI.',
                    'Chúng tôi không bao giờ bán dữ liệu của bạn và không dùng cho quảng cáo.',
                    'Chúng tôi chỉ thu thập những gì kế hoạch cần.',
                    'Bạn có thể yêu cầu xem, sửa, nhận bản sao hoặc xóa dữ liệu của mình bất cứ lúc nào.'
                ]
            },
            {
                h: '1. Dữ liệu chúng tôi thu thập',
                items: [
                    'Tài khoản: địa chỉ email của bạn. Khi đăng nhập bằng Google, chúng tôi chỉ nhận địa chỉ email — không nhận tên, danh bạ hay dữ liệu Google khác.',
                    'Kế hoạch của bạn: những gì bạn nhập để lập kế hoạch — ví dụ ngân sách, thu nhập, tiền tiết kiệm, khoản vay, tình trạng thị thực hoặc cư trú, tiểu bang và khu vực bạn quan tâm, và bất động sản bạn gắn vào.',
                    'Tài liệu bạn tải lên cho một bất động sản (như hợp đồng thuê), để kế hoạch đọc được.',
                    'Câu hỏi bạn gửi trợ lý AI và câu trả lời, lưu cùng kế hoạch.',
                    'Dữ liệu kỹ thuật: địa chỉ IP (để áp dụng giới hạn kế hoạch mới mỗi ngày và bảo vệ dịch vụ), loại trình duyệt và nhật ký lỗi.',
                    'Số lần sử dụng: bạn đã dùng bao nhiêu kế hoạch và câu hỏi AI, để áp dụng hạn mức miễn phí.'
                ]
            },
            {
                h: '2. Cookie và lưu trữ trên thiết bị của bạn',
                p: [
                    'Chúng tôi dùng một cookie đăng nhập để giữ bạn đăng nhập, và một cookie ngắn hạn trong lúc đăng nhập bằng Google. Trình duyệt của bạn cũng ghi nhớ ngôn ngữ và việc bạn đã xem hướng dẫn chào mừng hay chưa. Chúng tôi không dùng cookie quảng cáo hay theo dõi, và không dùng dịch vụ phân tích.'
                ]
            },
            {
                h: '3. Cách chúng tôi sử dụng dữ liệu',
                items: [
                    'Lập kế hoạch của bạn và cập nhật kế hoạch',
                    'Trả lời câu hỏi của bạn về kế hoạch',
                    'Đăng nhập cho bạn và gửi email đăng nhập',
                    'Áp dụng hạn mức miễn phí và bảo vệ dịch vụ khỏi lạm dụng',
                    'Tuân thủ nghĩa vụ pháp lý'
                ]
            },
            {
                h: '4. Bên xử lý dữ liệu cho chúng tôi',
                items: [
                    'Anthropic — mô hình AI lập một phần kế hoạch và trả lời câu hỏi của bạn. Anthropic nhận các chi tiết kế hoạch và câu hỏi cần cho câu trả lời đó, và không dùng dữ liệu này để huấn luyện mô hình.',
                    'DigitalOcean — máy chủ và cơ sở dữ liệu của chúng tôi, đặt tại Sydney, Úc.',
                    'Cloudflare — phân phối trang web và bảo vệ trang khỏi tấn công.',
                    'Resend — gửi email đăng nhập đến địa chỉ của bạn.',
                    'Google — chỉ khi bạn chọn đăng nhập bằng Google.'
                ],
                p: [
                    'Chúng tôi không chia sẻ dữ liệu với bất kỳ ai khác, trừ khi pháp luật, tòa án hoặc việc bảo vệ an toàn của một người đòi hỏi.'
                ]
            },
            {
                h: '5. Thời gian lưu giữ',
                items: [
                    'Kế hoạch lập khi chưa đăng nhập: 7 ngày, sau đó bị xóa. Đăng nhập trên cùng trình duyệt trong 7 ngày đó để giữ kế hoạch trong tài khoản.',
                    'Tài khoản, kế hoạch, tài liệu và câu hỏi của bạn: cho đến khi bạn yêu cầu xóa.',
                    'Số đếm hằng ngày cho giới hạn kế hoạch, cùng địa chỉ IP đi kèm: xóa sau 7 ngày.'
                ],
                p: [
                    'Khi bạn yêu cầu xóa tài khoản, chúng tôi xóa dữ liệu của bạn trong vòng 30 ngày, trừ phần pháp luật yêu cầu lưu giữ.'
                ]
            },
            {
                h: '6. Bảo mật',
                p: [
                    'Dữ liệu được truyền qua kết nối mã hóa (HTTPS). Đăng nhập dùng liên kết email một lần hoặc Google, không lưu mật khẩu. Quyền truy cập cơ sở dữ liệu chỉ dành cho những người vận hành dịch vụ.'
                ]
            },
            {
                h: '7. Quyền của bạn',
                items: [
                    'Xem dữ liệu cá nhân chúng tôi đang giữ về bạn',
                    'Sửa dữ liệu đó',
                    'Nhận một bản sao',
                    'Yêu cầu xóa tài khoản và dữ liệu',
                    'Rút lại sự đồng ý, bằng cách ngừng sử dụng và yêu cầu chúng tôi xóa dữ liệu'
                ],
                p: ['Gửi email đến info@maiancu.com từ địa chỉ bạn dùng để đăng nhập, chúng tôi sẽ phản hồi.']
            },
            {
                h: '8. Nơi dữ liệu được xử lý',
                p: [
                    'Máy chủ của chúng tôi đặt tại Úc. Nhà cung cấp AI và dịch vụ email có thể xử lý dữ liệu ở các nước khác, như Hoa Kỳ. Dữ liệu bạn gửi từ Việt Nam được chuyển sang Úc để cung cấp dịch vụ.'
                ]
            },
            {
                h: '9. Trẻ em',
                p: ['Mai An Cư dành cho người trưởng thành lập kế hoạch mua bất động sản, không dành cho người dưới 18 tuổi.']
            },
            {
                h: '10. Thay đổi',
                p: [
                    'Nếu thay đổi chính sách này, chúng tôi sẽ cập nhật ngày ở trên và thông báo trong ứng dụng khi thay đổi quan trọng.'
                ]
            },
            {
                h: '11. Liên hệ',
                p: ['Câu hỏi về chính sách này hoặc dữ liệu của bạn: info@maiancu.com']
            }
        ]
    }
};
