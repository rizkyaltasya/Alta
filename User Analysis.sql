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

    
    
	
