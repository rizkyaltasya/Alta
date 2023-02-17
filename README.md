# E-Commerce-Product-User-Analysis
### Product Analysis ###
SELECT 
	primary_product_id as primary_product,
    COUNT(order_id) AS orders,
    SUM(price_usd) AS revenue,
    SUM(price_usd - cogs_usd) AS margin,
    AVG(price_usd) as AOV
FROM
    orders
where
	order_id between 10000 and 11000
group by 1
order by 2 Desc;

### Product Level Sales Analysis ###
SELECT 
    YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(distinct order_id) AS number_of_sales,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM
    orders
WHERE
    created_at < '2013-01-04'
GROUP BY 2;

### Product Launches ###
SELECT 
    YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT website_sessions.website_session_id) AS total_sessions,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id) AS conv_rates,
    SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id) AS revenue_per_session,
    COUNT(DISTINCT CASE
            WHEN orders.primary_product_id = 1 THEN orders.order_id
            ELSE NULL
        END) AS product_one_order,
    COUNT(DISTINCT CASE
            WHEN orders.primary_product_id = 2 THEN orders.order_id
            ELSE NULL
        END) AS product_two_order
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at BETWEEN '2012-04-01' AND '2013-04-01'
GROUP BY 1,2;

### Analyzing Product-Level Website Pathing ###
select pageview_url from website_pageviews
group by 1;

SELECT 
    website_pageviews.pageview_url,
    COUNT(DISTINCT website_pageviews.website_session_id) AS total_sessions,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_pageviews.website_session_id) as viewed_product_to_orders
FROM
    website_pageviews
        LEFT JOIN
    orders ON website_pageviews.website_session_id = orders.website_session_id
WHERE
    website_pageviews.created_at BETWEEN '2013-02-01' AND '2013-03-01'
        AND pageview_url IN ('/the-original-mr-fuzzy' , '/the-forever-love-bear')
GROUP BY 1;

create temporary table product_pageviews;
SELECT 
    website_session_id,
    website_pageview_id,
    created_at,
    CASE
        WHEN created_at < '2013-01-06' THEN 'A.Pre_Product_2'
        WHEN created_at > '2013-01-06' THEN 'A.Post_Product_2'
        ELSE 'uh ah...logic'
    END AS time_period
FROM
    website_pageviews
WHERE
    created_at < '2013-04-06'
        AND created_at > '2012-10-06'
        AND pageview_url = '/products';

create temporary table sessions_next_pageview_url;  
SELECT 
    product_pageviews.time_period,
    product_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pageview_id
FROM
    product_pageviews
        LEFT JOIN
    website_pageviews ON website_pageviews.website_session_id = product_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > product_pageviews.website_pageview_id
GROUP BY 1 , 2;

drop temporary table if exists sessions_pageview_url;
create temporary table sessions_pageview_url;
SELECT 
    sessions_next_pageview_url.time_period,
    sessions_next_pageview_url.website_session_id,
    website_pageviews.pageview_url as next_pageview_url
FROM
    sessions_next_pageview_url
        LEFT JOIN
    website_pageviews ON sessions_next_pageview_url.min_pageview_id = website_pageviews.website_pageview_id;
    
SELECT 
    time_period,
    COUNT(DISTINCT website_session_id) as sessions,
    COUNT(DISTINCT CASE
            WHEN next_pageview_url IS NOT NULL THEN website_session_id
            ELSE NULL
        END) AS next_pv,
    COUNT(DISTINCT CASE
            WHEN next_pageview_url IS NOT NULL THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT website_session_id) AS percentage_pv,
    COUNT(DISTINCT CASE
            WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id
            ELSE NULL
        END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE
            WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT website_session_id) AS percentage_mrfuzzy,
    COUNT(DISTINCT CASE
            WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id
            ELSE NULL
        END) AS to_lovebear,
    COUNT(DISTINCT CASE
            WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id
            ELSE NULL
        END) / COUNT(DISTINCT website_session_id) AS percentage_lovebear
FROM
    sessions_pageview_url
GROUP BY 1;

### Product Level Conversion Funnel ###

select pageview_url from website_pageviews
group by pageview_url;

drop temporary table if exists session_seeing_product_pages;
create temporary table session_seeing_product_pages
SELECT 
    website_session_id,
    website_pageview_id,
    pageview_url AS product_page_seen
FROM
    website_pageviews
WHERE
    created_at BETWEEN '2013-01-06' AND '2013-04-10'
        AND pageview_url IN ('/the-original-mr-fuzzy' , '/the-forever-love-bear');
        
select distinct
	website_pageviews.pageview_url
from
	session_seeing_product_pages
		left join
	website_pageviews on website_pageviews.website_session_id = session_seeing_product_pages.website_session_id
    and session_seeing_product_pages.website_pageview_id < website_pageviews.website_pageview_id;
	
SELECT 
    session_seeing_product_pages.website_session_id,
    session_seeing_product_pages.product_page_seen,
    CASE
        WHEN pageview_url = '/cart' THEN 1
        ELSE 0
    END AS cart_page,
    CASE
        WHEN pageview_url = '/shipping' THEN 1
        ELSE 0
    END AS shipping_page,
    CASE
        WHEN pageview_url = '/billing-2' THEN 1
        ELSE 0
    END AS billing_page,
    CASE
        WHEN pageview_url = '/thank-you-for-your-order' THEN 1
        ELSE 0
    END AS thankyou_page
FROM
    session_seeing_product_pages
        LEFT JOIN
    website_pageviews ON session_seeing_product_pages.website_session_id = website_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > session_seeing_product_pages.website_pageview_id
ORDER BY session_seeing_product_pages.website_session_id , website_pageviews.created_at;

create temporary table session_pageview_level;
SELECT 
    website_session_id,
    CASE
        WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'uh ah check logic'
    END AS product_seen,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM
    (SELECT 
        session_seeing_product_pages.website_session_id,
            session_seeing_product_pages.product_page_seen,
            CASE
                WHEN pageview_url = '/cart' THEN 1
                ELSE 0
            END AS cart_page,
            CASE
                WHEN pageview_url = '/shipping' THEN 1
                ELSE 0
            END AS shipping_page,
            CASE
                WHEN pageview_url = '/billing-2' THEN 1
                ELSE 0
            END AS billing_page,
            CASE
                WHEN pageview_url = '/thank-you-for-your-order' THEN 1
                ELSE 0
            END AS thankyou_page
    FROM
        session_seeing_product_pages
    LEFT JOIN website_pageviews ON session_seeing_product_pages.website_session_id = website_pageviews.website_session_id
        AND website_pageviews.website_pageview_id > session_seeing_product_pages.website_pageview_id
    ORDER BY session_seeing_product_pages.website_session_id , website_pageviews.created_at) AS pageview_level
GROUP BY website_session_id , CASE
    WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
    WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
    ELSE 'uh ah check logic'
END;

select * from website_sessions;

SELECT 
    product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE
            WHEN cart_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS cart_sessions,
    COUNT(DISTINCT CASE
            WHEN shipping_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS shipping_sessions,
    COUNT(DISTINCT CASE
            WHEN billing_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS billing_sessions,
    COUNT(DISTINCT CASE
            WHEN thankyou_made_it = 1 THEN website_session_id
            ELSE NULL
        END) AS thankyou_session
FROM
    session_pageview_level
GROUP BY 1;
    
SELECT 
    product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE
            WHEN cart_made_it = 1 THEN website_session_id
            ELSE NULL
        END)/COUNT(DISTINCT website_session_id) AS cart_conversion,
    COUNT(DISTINCT CASE
            WHEN shipping_made_it = 1 THEN website_session_id
            ELSE NULL
        END)/COUNT(DISTINCT website_session_id) AS shipping_conversion,
    COUNT(DISTINCT CASE
            WHEN billing_made_it = 1 THEN website_session_id
            ELSE NULL
        END)/COUNT(DISTINCT website_session_id) AS billing_conversion,
    COUNT(DISTINCT CASE
            WHEN thankyou_made_it = 1 THEN website_session_id
            ELSE NULL
        END)/COUNT(DISTINCT website_session_id) AS thankyou_conversion
FROM
    session_pageview_level
GROUP BY 1;
     
### Cross Selling & Product Portfolio Analysis ###
SELECT 
    *
FROM
    order_items;
    
SELECT 
    orders.primary_product_id,
    COUNT(DISTINCT orders.order_id) AS total_order_products,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 1 THEN orders.order_id
            ELSE NULL
        END) AS x_sell_prod1,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 2 THEN orders.order_id
            ELSE NULL
        END) AS x_sell_prod2,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 3 THEN orders.order_id
            ELSE NULL
        END) AS x_sell_prod3
FROM
    orders
        LEFT JOIN
    order_items ON orders.order_id = order_items.order_id
        AND order_items.is_primary_item = 0
WHERE
    orders.order_id BETWEEN 10000 AND 11000
GROUP BY 1; 

SELECT 
    *
FROM
    order_items;

drop temporary table session_seeing_cart;
create temporary table session_seeing_cart
SELECT 
    CASE
        WHEN created_at >= '2013-09-25' THEN 'Post_Cross_Sell'
        WHEN created_at < '2013-09-25' THEN 'Pre_Cross_Sell'
        ELSE 'uh ah logic'
    END AS time_period,
    website_session_id as cart_session_id,
    website_pageview_id
FROM
    website_pageviews
WHERE
    created_at BETWEEN '2013-08-25' AND '2013-10-25'
        AND pageview_url = '/cart';
 
create temporary table session_seeing_cart_next_session;
SELECT 
    session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv_after_cart
FROM
    session_seeing_cart
        LEFT JOIN
    website_pageviews ON website_pageviews.website_session_id = session_seeing_cart.cart_session_id
        AND website_pageviews.website_pageview_id > session_seeing_cart.website_pageview_id
GROUP BY 1 , 2
HAVING MIN(website_pageviews.website_pageview_id) IS NOT NULL;

create temporary table pre_post_session_order;
SELECT 
    session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id,
    orders.order_id,
    orders.items_purchased,
    orders.price_usd
FROM
    session_seeing_cart
        INNER JOIN
    orders ON session_seeing_cart.cart_session_id = orders.website_session_id;
    
SELECT 
    session_seeing_cart.time_period,
    session_seeing_cart.cart_session_id,
    CASE
        WHEN pre_post_session_order.order_id IS NULL THEN 0
        ELSE 1
    END AS placed_order,
    CASE
        WHEN session_seeing_cart_next_session.cart_session_id IS NULL THEN 0
        ELSE 1
    END AS clicked_next_page,
    pre_post_session_order.items_purchased,
    pre_post_session_order.price_usd
FROM
    session_seeing_cart
        LEFT JOIN
    session_seeing_cart_next_session ON session_seeing_cart.cart_session_id = session_seeing_cart_next_session.cart_session_id
        LEFT JOIN
    pre_post_session_order ON session_seeing_cart_next_session.cart_session_id = pre_post_session_order.cart_session_id
ORDER BY session_seeing_cart.cart_session_id;

SELECT 
    time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_next_page) AS clickthrough_next_step,
    SUM(clicked_next_page) / COUNT(DISTINCT cart_session_id) AS cart_ctr,
    SUM(placed_order) AS order_placed,
    SUM(items_purchased) AS item_purchased,
    SUM(items_purchased) / SUM(placed_order) AS products_per_order,
    SUM(price_usd) AS price,
    SUM(price_usd) / SUM(placed_order) AS aov,
    SUM(price_usd) / COUNT(DISTINCT cart_session_id) AS revenue_per_session
FROM
    (SELECT 
        session_seeing_cart.time_period,
            session_seeing_cart.cart_session_id,
            CASE
                WHEN pre_post_session_order.order_id IS NULL THEN 0
                ELSE 1
            END AS placed_order,
            CASE
                WHEN session_seeing_cart_next_session.cart_session_id IS NULL THEN 0
                ELSE 1
            END AS clicked_next_page,
            pre_post_session_order.items_purchased,
            pre_post_session_order.price_usd
    FROM
        session_seeing_cart
    LEFT JOIN session_seeing_cart_next_session ON session_seeing_cart.cart_session_id = session_seeing_cart_next_session.cart_session_id
    LEFT JOIN pre_post_session_order ON session_seeing_cart_next_session.cart_session_id = pre_post_session_order.cart_session_id
    ORDER BY session_seeing_cart.cart_session_id) AS next_session
GROUP BY 1;

select pageview_url from website_pageviews
group by 1;

#Analyzing Products Portfolio#
create temporary table session_seeing_lovebear;
SELECT 
    CASE
        WHEN created_at < '2013-12-12' THEN 'pre-cross-sell'
        WHEN created_at > '2013-12-12' THEN 'post-cross-sell'
        ELSE 'uh ah logic'
    END AS time_period,
    website_session_id AS product_session
FROM
    website_pageviews
WHERE
    created_at < '2014-01-12'
        AND pageview_url = '/the-forever-love-bear';

SELECT 
    CASE
        WHEN website_sessions.created_at < '2013-12-12' THEN 'pre-cross-sell'
        WHEN website_sessions.created_at > '2013-12-12' THEN 'post-cross-sell'
        ELSE 'uh ah logic'
    END AS time_period,
    COUNT(website_sessions.website_session_id) AS total_sessions,
    COUNT(orders.order_id) AS total_orders,
    COUNT(orders.order_id) / COUNT(website_sessions.website_session_id) AS conv_rate,
    SUM(items_purchased) AS item_puchased,
    SUM(items_purchased) / COUNT(orders.order_id) AS products_to_order,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd) / COUNT(website_sessions.website_session_id) AS revenue_per_session
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at BETWEEN '2013-11-12' AND '2014-01-12'
GROUP BY 1;

### Analyzing_Product_Refund ###
SELECT 
    order_items.order_id,
    order_items.order_item_id,
    order_items.price_usd,
    order_item_refunds.order_item_refund_id,
    order_item_refunds.refund_amount_usd
FROM
    order_items
        LEFT JOIN
    order_item_refunds ON order_items.order_item_id = order_item_refunds.order_item_id
WHERE
    order_items.order_id IN (3489 , 32049, 27061);
    
SELECT 
    YEAR(order_items.created_at) as year,
    MONTH(order_items.created_at) as month,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 1 THEN order_items.order_item_id
            ELSE NULL
        END) AS p1_orders,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 1 THEN order_item_refunds.order_item_id
            ELSE NULL
        END) AS p1_refunds,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 2 THEN order_items.order_item_id
            ELSE NULL
        END) AS p2_orders,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 2 THEN order_item_refunds.order_item_id
            ELSE NULL
        END) AS p2_refunds,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 3 THEN order_items.order_item_id
            ELSE NULL
        END) AS p3_orders,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 3 THEN order_item_refunds.order_item_id
            ELSE NULL
        END) AS p3_refunds,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 4 THEN order_items.order_item_id
            ELSE NULL
        END) AS p4_orders,
    COUNT(DISTINCT CASE
            WHEN order_items.product_id = 4 THEN order_item_refunds.order_item_id
            ELSE NULL
        END) AS p4_refunds
FROM
    order_items
        LEFT JOIN
    order_item_refunds ON order_items.order_item_id = order_item_refunds.order_item_id
WHERE
    order_items.created_at < '2014-10-15'
GROUP BY 1 , 2;
	
SELECT 
    utm_campaign
FROM
    website_sessions
GROUP BY 1;

select utm_source from website_sessions
group by 1;
    
SELECT 
    date(website_sessions.created_at) as date,
    COUNT(DISTINCT website_sessions.website_session_id) as total_sessions,
    COUNT(DISTINCT orders.order_id) as total_orders,
    COUNT(DISTINCT CASE
            WHEN
                utm_source = 'gsearch'
                    AND utm_campaign = 'nonbrand'
            THEN
                website_sessions.website_session_id
            ELSE NULL
        END) AS gsearch_nonbrand,
    COUNT(DISTINCT CASE
            WHEN
                utm_source = 'bsearch'
                    AND utm_campaign = 'nonbrand'
            THEN
                website_sessions.website_session_id
            ELSE NULL
        END) AS bsearch_nonbrand,
    COUNT(DISTINCT CASE
            WHEN
                utm_source = 'gsearch'
                    AND utm_campaign = 'brand'
            THEN
                website_sessions.website_session_id
            ELSE NULL
        END) AS gsearch_brand,
    COUNT(DISTINCT CASE
            WHEN
                utm_source = 'bsearch'
                    AND utm_campaign = 'brand'
            THEN
                website_sessions.website_session_id
            ELSE NULL
        END) AS gsearch_brand
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at BETWEEN '2014-01-01' AND '2015-01-01'
GROUP BY MONTH(website_sessions.created_at);

SELECT 
    COUNT(DISTINCT website_sessions.website_session_id) AS total_sessions,
    COUNT(DISTINCT orders.order_id) AS total_orders,
    website_sessions.created_at AS date
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at BETWEEN '2014-12-24' AND '2014-12-31';
    
SELECT 
    website_sessions.website_session_id,
    orders.website_session_id
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at BETWEEN '2013-01-01' AND '2014-01-01';

drop temporary table if exists bounce_session;
create temporary table first_pageview
SELECT 
    website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS min_pv,
    website_pageviews.pageview_url
FROM
    website_pageviews
        INNER JOIN
    website_sessions ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
    website_sessions.created_at BETWEEN '2014-01-01' AND '2015-01-01'
GROUP BY 1;

SELECT 
    *
FROM
    first_pageview;

select
	pageview_url
from
	website_pageviews
group by 1;

create temporary table session_landing_page;
SELECT 
    first_pageview.website_session_id,
    website_pageviews.pageview_url,
    COUNT(website_pageviews.website_pageview_id) AS total_view
FROM
    first_pageview
        LEFT JOIN
    website_pageviews ON website_pageviews.website_pageview_id = first_pageview.min_pv
WHERE
    pageview_url = '/home'
GROUP BY 1;

SELECT 
    *
FROM
    session_landing_page;

drop temporary table if exists first_pageview;

create temporary table bounce_session;
SELECT 
    session_landing_page.website_session_id,
    session_landing_page.pageview_url,
    COUNT(website_pageviews.website_pageview_id) AS bounce_session
FROM
    session_landing_page
        LEFT JOIN
    website_pageviews ON session_landing_page.website_session_id = website_pageviews.website_session_id
GROUP BY 1 , 2
HAVING COUNT(website_pageviews.website_pageview_id) = 1;

     
SELECT 
    session_landing_page.pageview_url,
    COUNT(DISTINCT session_landing_page.website_session_id) as total_sessions,
    COUNT(DISTINCT bounce_session.website_session_id) as total_bounces,
    COUNT(DISTINCT bounce_session.website_session_id) / COUNT(DISTINCT session_landing_page.website_session_id) as bounce_rate
FROM
    session_landing_page
        LEFT JOIN
    bounce_session ON session_landing_page.website_session_id = bounce_session.website_session_id;

SELECT 
    DATE(website_sessions.created_at) AS date,
    MONTH(website_sessions.created_at) AS month,
    COUNT(DISTINCT session_landing_page.website_session_id) AS total_sessions,
    COUNT(DISTINCT bounce_session.website_session_id) AS total_bounces,
    COUNT(DISTINCT bounce_session.website_session_id) / COUNT(DISTINCT session_landing_page.website_session_id) AS bounce_rate
FROM
    website_sessions
        LEFT JOIN
    session_landing_page ON website_sessions.website_session_id = session_landing_page.website_session_id
        LEFT JOIN
    bounce_session ON session_landing_page.website_session_id = bounce_session.website_session_id
WHERE
    website_sessions.created_at BETWEEN '2014-01-01' AND '2015-01-01'
GROUP BY 2;

SELECT 
    *
FROM
    website_pageviews
WHERE
    created_at < '2012-09-06'
GROUP BY website_session_id , pageview_url
ORDER BY website_session_id, website_pageview_id;

##### USER ANALYSIS ####
SELECT 
    order_items.order_id,
    order_items.order_item_id,
    order_items.price_usd AS price_paid_usd,
    order_items.created_at as day_order,
    order_item_refunds.order_item_refund_id,
    order_item_refunds.refund_amount_usd,
    order_item_refunds.created_at as day_refund,
    DATEDIFF(order_item_refunds.created_at, order_items.created_at) as days_order_to_refund
FROM
    order_items
        LEFT JOIN
    order_item_refunds ON order_item_refunds.order_item_id = order_items.order_item_id
WHERE
    order_items.order_id IN (3489 , 32049, 27061);
    
select * from order_items;

### Identifying Repeat Visitor ###
create temporary table new_and_repeat_session;
SELECT 
    new_session.user_id,
    new_session.website_session_id as new_session_id,
    website_sessions.website_session_id as repeat_session_id
FROM
    (SELECT 
        user_id, 
        website_session_id
    FROM
        website_sessions
    WHERE
        created_at BETWEEN '2014-01-01' AND '2014-11-01'
            AND is_repeat_session = 0) AS new_session
        LEFT JOIN
    website_sessions ON website_sessions.user_id = new_session.user_id
        AND website_sessions.is_repeat_session = 1
        AND website_sessions.website_session_id > new_session.website_session_id
        AND website_sessions.created_at < '2014-11-01'
        AND website_sessions.created_at >= '2014-01-01';
        
SELECT 
    repeat_sessions, 
    COUNT(DISTINCT user_id) AS users
FROM
    (SELECT 
        user_id,
		COUNT(DISTINCT new_session_id) AS new_sessions,
		COUNT(DISTINCT repeat_session_id) AS repeat_sessions
    FROM
        new_and_repeat_session
    GROUP BY 1
    ORDER BY 3) AS user_level
GROUP BY 1;

### Analyzing Time To Repeat ###
drop temporary table if exists session_for_repeat_and_new;
create temporary table session_for_repeat_and_new
SELECT 
    new_session.user_id,
    new_session.website_session_id as new_session_id,
    new_session.created_at as date_new_session,
    website_sessions.website_session_id as repeat_session_id,
    website_sessions.created_at as date_repeat_session
FROM
    (SELECT 
        user_id, 
        website_session_id,
        created_at
    FROM
        website_sessions
    WHERE
        created_at BETWEEN '2014-01-01' AND '2014-11-01'
            AND is_repeat_session = 0) AS new_session
        LEFT JOIN
    website_sessions ON website_sessions.user_id = new_session.user_id
        AND website_sessions.is_repeat_session = 1
        AND website_sessions.website_session_id > new_session.website_session_id
        AND website_sessions.created_at < '2014-11-03'
        AND website_sessions.created_at >= '2014-01-01';
        
SELECT 
    user_id,
    new_session_id,
    date_new_session,
    MIN(repeat_session_id) as second_session,
    MIN(date_repeat_session) as date_second_session
FROM
    session_for_repeat_and_new
where
	repeat_session_id is not null
GROUP BY 1, 2, 3;

create temporary table first_to_second
SELECT 
    user_id,
    DATEDIFF(date_second_session, date_new_session) AS date_first_to_second
FROM
    (SELECT 
        user_id,
		new_session_id,
		date_new_session,
		MIN(repeat_session_id) AS second_session,
		MIN(date_repeat_session) AS date_second_session
    FROM
        session_for_repeat_and_new
    WHERE
        repeat_session_id IS NOT NULL
    GROUP BY 1 , 2 , 3) AS first_to_second;
    
SELECT 
    MIN(date_first_to_second) as min_date_first_to_second,
    MAX(date_first_to_second) as max_date_first_to_second,
    AVG(date_first_to_second) as average_date_first_to_second
FROM
    first_to_second;
    
### Analyzing Repeat Channel Behavior ###
SELECT 
    utm_source,
    utm_campaign,
    http_referer,
    COUNT(CASE
        WHEN is_repeat_session = 0 THEN website_session_id
        ELSE NULL
    END) AS new_sessions,
    COUNT(CASE
        WHEN is_repeat_session = 1 THEN website_session_id
        ELSE NULL
    END) AS repeat_sessions
FROM
    website_sessions
WHERE
    created_at >= '2014-01-01'
        AND created_at < '2014-11-05'
GROUP BY 1 , 2 , 3
ORDER BY 4 DESC;

SELECT 
    CASE
        WHEN
            utm_source IS NULL
                AND http_referer IS NULL
        THEN
            'direct_type_in'
        WHEN
            utm_source IS NULL
                AND http_referer IS NOT NULL
        THEN
            'organic_search'
        WHEN utm_campaign = 'nonbrand' THEN 'paid_nonbrand'
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
    END AS channel_group,
    COUNT(DISTINCT CASE
            WHEN is_repeat_session = 0 THEN website_session_id
            ELSE NULL
        END) AS new_sessions,
    COUNT(DISTINCT CASE
            WHEN is_repeat_session = 0 THEN website_session_id
            ELSE NULL
        END) AS repeat_sessions
FROM
    website_sessions
WHERE
    created_at >= '2014-01-01'
        AND created_at < '2014-11-05'
GROUP BY 1;

SELECT 
    utm_campaign, utm_source, http_referer
FROM
    website_sessions
WHERE
    created_at BETWEEN '2014-01-01' AND '2015-01-01'
GROUP BY 1 , 2 , 3;

SELECT 
    website_sessions.is_repeat_session,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS conv_rate,
    SUM(price_usd) AS total_revenue
FROM
    website_sessions
        LEFT JOIN
    orders ON website_sessions.website_session_id = orders.website_session_id
WHERE
    website_sessions.created_at >= '2014-01-01'
        AND website_sessions.created_at < '2014-11-05'
GROUP BY 1;

    
    
	



    
    




    





